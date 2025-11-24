import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'https://janna-server.onrender.com/api';

  static Future<Map<String, dynamic>> registerDoctor(
    Map<String, dynamic> data, {
    Uint8List? validIdImage,
    String? validIdFileName,
  }) async {
    final url = Uri.parse('$baseUrl/auth/doctors');

    try {
      final request = http.MultipartRequest('POST', url);

      // Add text fields
      data.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Add valid ID image if provided
      if (validIdImage != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'valid_id',
            validIdImage,
            filename: validIdFileName ?? 'valid_id.jpg',
          ),
        );
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final body = jsonDecode(responseBody);

      if (streamedResponse.statusCode == 201) {
        return {'success': true, 'data': body};
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Failed to register doctor.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> registerClient(
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/auth/clients');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': body};
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Failed to register doctor.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // Assuming JWT is returned in `token`
        return {'success': true, 'token': body['token'], 'user': body['user']};
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Login failed.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyAccount(
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/auth/verify');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': body['message'],
          'tabs': body['tabs'],
          'role': body['role'],
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Verification failed.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ✅ Admin: Get pending doctors
  static Future<List<dynamic>> getPendingDoctors() async {
    final url = Uri.parse('$baseUrl/auth/pending-doctors');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch pending doctors');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ✅ Admin: Approve doctor
  static Future<Map<String, dynamic>> approveDoctor(int doctorId) async {
    final url = Uri.parse('$baseUrl/auth/approve-doctor/$doctorId');

    try {
      final response = await http.put(url);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message']};
      } else {
        return {'success': false, 'message': body['message'] ?? 'Failed to approve doctor'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ✅ Admin: Reject doctor
  static Future<Map<String, dynamic>> rejectDoctor(int doctorId, {String? reason}) async {
    final url = Uri.parse('$baseUrl/auth/reject-doctor/$doctorId');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reason': reason}),
      );
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message']};
      } else {
        return {'success': false, 'message': body['message'] ?? 'Failed to reject doctor'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
