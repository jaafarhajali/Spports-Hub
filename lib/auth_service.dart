import 'dart:convert';
import 'package:first_attempt/services/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = '${AppConfig.apiUrl}/auth';

  // Store token
  Future<void> storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Save token (alias for storeToken for consistency with team service)
  Future<void> saveToken(String token) async {
    await storeToken(token);
  }

  // Get token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Store remember me preference
  Future<void> setRememberMe(bool remember) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', remember);
  }

  // Get remember me preference
  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('remember_me') ?? false;
  }

  // Check if user should stay logged in
  Future<bool> shouldStayLoggedIn() async {
    final token = await getToken();
    final rememberMe = await getRememberMe();
    return token != null && token.isNotEmpty && rememberMe;
  }

  // Store user data
  Future<void> storeUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'user_name',
      userData['name'] ?? userData['username'] ?? '',
    );
    await prefs.setString('user_email', userData['email'] ?? '');
    await prefs.setString(
      'user_image',
      userData['image'] ?? userData['profileImage'] ?? '',
    );
  }

  // Get user data
  Future<Map<String, String>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('user_name') ?? '',
      'email': prefs.getString('user_email') ?? '',
      'image': prefs.getString('user_image') ?? '',
    };
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
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
        final data = jsonDecode(response.body); // Store token if available
        if (data['token'] != null) {
          await storeToken(data['token']);
        }

        // Store user data if available
        if (data['user'] != null) {
          await storeUserData(data['user']);
        } else if (data.containsKey('name') ||
            data.containsKey('username') ||
            data.containsKey('email')) {
          // If user data is at root level
          await storeUserData(data);
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

  // Get user role from stored token
  Future<String?> getUserRole() async {
    try {
      final token = await getToken();
      if (token == null) return null;
      
      // Decode JWT token to get user role
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> data = jsonDecode(decoded);
      
      return data['role']?.toString();
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Get user ID from stored token
  Future<String?> getUserId() async {
    try {
      final token = await getToken();
      if (token == null) return null;
      
      // Decode JWT token to get user ID
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> data = jsonDecode(decoded);
      
      return data['userId']?.toString() ?? data['id']?.toString();
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('remember_me');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_image');
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
