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
      // If there's an image, use multipart request
      if (validIdImage != null && validIdFileName != null) {
        var request = http.MultipartRequest('POST', url);

        // Add all form fields
        data.forEach((key, value) {
          if (value != null) {
            request.fields[key] = value.toString();
          }
        });

        // Add the image file
        request.files.add(
          http.MultipartFile.fromBytes(
            'valid_id',
            validIdImage,
            filename: validIdFileName,
          ),
        );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        final body = jsonDecode(response.body);

        if (response.statusCode == 201) {
          return {'success': true, 'data': body};
        } else {
          return {
            'success': false,
            'message': body['message'] ?? 'Failed to register doctor.',
          };
        }
      } else {
        // No image, use regular JSON request
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
}
