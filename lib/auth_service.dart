import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl =
      'http://192.168.0.106:8080/api/auth'; // Replace with your IP

  // Store token
  Future<void> storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Get token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Register
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      final result = _handleResponse(response);

      // Store token if available
      if (result.containsKey('token')) {
        await storeToken(result['token']);
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Login - supports both username and email
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      // Log the request for debugging
      print('Sending login request to: $baseUrl/login');
      print('Request data: {"username": "$username", "password": "****"}');

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          // Try both username and email fields since your schema supports both
          'username': username,
          'email': username, // Also send as email in case backend expects this
          'password': password,
        }),
      );

      // Log response for debugging
      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      // Parse and return response
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Store token if available
        if (data['token'] != null) {
          await storeToken(data['token']);
        }

        return {'success': true, ...data};
      } else {
        // Try to parse error message
        try {
          final data = jsonDecode(response.body);
          final message =
              data['message'] ??
              'Login failed with status: ${response.statusCode}';
          return {'success': false, 'message': message};
        } catch (e) {
          return {
            'success': false,
            'message': 'Login failed with status: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      print('Login error: ${e.toString()}');
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Process HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      print('Response status: ${response.statusCode}'); // Add logging
      print('Response body: $data'); // Add logging

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        final message = data['message'] ?? 'Unknown error occurred';
        return {'success': false, 'message': message};
      }
    } catch (e) {
      print('Response parsing error: ${e.toString()}'); // Add logging
      return {'success': false, 'message': 'Failed to parse response'};
    }
  }
}
