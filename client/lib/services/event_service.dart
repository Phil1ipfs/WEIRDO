import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EventService {
  static const String baseUrl = 'https://janna-server.onrender.com/api';

  // 🗑️ Delete event
  static Future<bool> deleteEvent(int eventId) async {
    final uri = Uri.parse('$baseUrl/events/$eventId');
    try {
      final response = await http.delete(uri);
      if (response.statusCode == 200) return true;
      final data = json.decode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete event');
    } catch (e) {
      throw Exception('Error deleting event: $e');
    }
  }

  // 📤 Upload event + notify all users
  static Future<Map<String, dynamic>> uploadEvent({
    required String title,
    required String description,
    required String date,
    required String time,
    required String location,
    required String status,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final uri = Uri.parse('$baseUrl/events');
    final request = http.MultipartRequest('POST', uri)
      ..fields['title'] = title
      ..fields['description'] = description
      ..fields['date'] = date
      ..fields['time'] = time
      ..fields['location'] = location
      ..fields['status'] = status;

    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageName ?? 'event_image.jpg',
        ),
      );
    }

    try {
      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      // Check if response is HTML (error page) instead of JSON
      if (responseBody.trim().startsWith('<!DOCTYPE') ||
          responseBody.trim().startsWith('<html')) {
        return {
          'success': false,
          'message': 'Server error: Received HTML response instead of JSON. Status: ${streamedResponse.statusCode}',
        };
      }

      // Try to parse JSON
      Map<String, dynamic> data;
      try {
        data = json.decode(responseBody);
      } catch (e) {
        return {
          'success': false,
          'message': 'Invalid server response. Status: ${streamedResponse.statusCode}',
        };
      }

      if (streamedResponse.statusCode == 201) {
        print('✅ Event uploaded successfully.');

        // 📨 Send notifications to all doctors and clients
        await _notifyUsersAboutEvent(
          eventTitle: title,
          eventDate: date,
          eventTime: time,
          eventLocation: location,
          eventDescription: description,
        );

        return {
          'success': true,
          'message': data['message'] ?? 'Event uploaded successfully.',
          'event': data['event'],
        };
      } else {
        // Include error details from server
        String errorMsg = data['message'] ?? 'Failed to upload event.';
        if (data['error'] != null) {
          errorMsg += '\nDetails: ${data['error']}';
        }
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error uploading event: $e'};
    }
  }

  // 🔔 Fetch all doctors and clients, then send them emails
  static Future<void> _notifyUsersAboutEvent({
    required String eventTitle,
    required String eventDate,
    required String eventTime,
    required String eventLocation,
    required String eventDescription,
  }) async {
    try {
      final uri = Uri.parse('https://janna-server.onrender.com/api/auth/users/with-roles');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);

        for (var user in users) {
          final email = user['email'];
          final firstName = user['first_name'] ?? 'User';

          await _sendEventEmail(
            toEmail: email,
            firstName: firstName,
            eventTitle: eventTitle,
            eventDate: eventDate,
            eventTime: eventTime,
            eventLocation: eventLocation,
            eventDescription: eventDescription,
            eventLink: 'https://yourapp.com/events',
          );
        }

        print('📢 Notifications sent to ${users.length} users.');
      } else {
        print('⚠️ Failed to fetch users for notification.');
      }
    } catch (e) {
      print('❌ Error sending notifications: $e');
    }
  }

  // 📧 Send email via EmailJS
  static Future<void> _sendEventEmail({
    required String toEmail,
    required String firstName,
    required String eventTitle,
    required String eventDate,
    required String eventTime,
    required String eventLocation,
    required String eventDescription,
    required String eventLink,
  }) async {
    try {
      final emailResponse = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': 'service_lwmhzvz',
          'template_id': 'template_6r1bvx8',
          'user_id': 'NqGto92Fuhj7llwi-',
          'template_params': {
            'to_email': toEmail,
            'first_name': firstName,
            'event_title': eventTitle,
            'event_date': eventDate,
            'event_time': eventTime,
            'event_location': eventLocation,
            'event_description': eventDescription,
            'event_link': eventLink,
          },
        }),
      );

      if (emailResponse.statusCode == 200 || emailResponse.statusCode == 202) {
        print("✅ Email sent to $toEmail");
      } else {
        print("⚠️ Email failed for $toEmail: ${emailResponse.body}");
      }
    } catch (e) {
      print("❌ Error sending email: $e");
    }
  }

  // 📅 Fetch all events
  static Future<List<Map<String, dynamic>>> getAllEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final uri = Uri.parse('$baseUrl/events');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch events');
    }
  }

  // 🔁 Update past events
  static Future<void> updatePastEvents() async {
    final uri = Uri.parse('$baseUrl/events/update-past');
    final response = await http.put(uri);
    if (response.statusCode == 200) {
      print('✅ Past events updated');
    } else {
      print('⚠️ Failed to update past events');
    }
  }

  // 🟢 Register event
  static Future<Map<String, dynamic>> registerForEvent(int eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      print('🔑 Token: ${token?.substring(0, 20)}...');

      if (token == null) throw Exception('No authentication token found.');

      final uri = Uri.parse('$baseUrl/events/register');
      print('📤 Registering for event $eventId');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'event_id': eventId}),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message']};
      } else {
        // Include error details from server
        String errorMsg = data['message'] ?? 'Failed to register';
        if (data['error'] != null) {
          errorMsg += ': ${data['error']}';
        }
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      print('❌ Error in registerForEvent: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ❌ Cancel registration
  static Future<Map<String, dynamic>> cancelRegistration(int eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      print('🔑 Token: ${token?.substring(0, 20)}...');

      if (token == null) throw Exception('No authentication token found.');

      final uri = Uri.parse('$baseUrl/events/cancel');
      print('🚫 Cancelling registration for event $eventId');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'event_id': eventId}),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        // Include error details from server
        String errorMsg = data['message'] ?? 'Failed to cancel registration';
        if (data['error'] != null) {
          errorMsg += ': ${data['error']}';
        }
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      print('❌ Error in cancelRegistration: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getRegisteredUsers(int eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/events/$eventId/registrations'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to fetch registered users (code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Error fetching registered users: $e');
    }
  }
}
