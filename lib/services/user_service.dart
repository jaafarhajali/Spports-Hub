import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:first_attempt/services/app_config.dart';

class UserService {
  final String baseUrl = '${AppConfig.apiUrl}/users';

  // Get stored token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Get user data from local storage (from token data)
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final token = await _getToken();
      if (token == null) {
        print('No token found');
        return null;
      }

      print('Token found, decoding...');

      // Decode JWT token to get user data
      final parts = token.split('.');
      if (parts.length != 3) {
        print('Invalid token format');
        return null;
      }

      final payload = parts[1];

      // Add padding if needed for base64 decoding
      String normalizedPayload = payload;
      switch (payload.length % 4) {
        case 1:
          normalizedPayload += '===';
          break;
        case 2:
          normalizedPayload += '==';
          break;
        case 3:
          normalizedPayload += '=';
          break;
      }

      final data = utf8.decode(base64Url.decode(normalizedPayload));
      final userData = jsonDecode(data);

      print('Decoded user data: $userData');

      return {
        'id': userData['id'],
        'username': userData['username'],
        'email': userData['email'],
        'phoneNumber': userData['phoneNumber'],
        'profilePhoto': userData['profilePhoto'],
        'role': userData['role'],
        'isActive': userData['isActive'],
        'termsAccepted': userData['termsAccepted'],
        'createdAt': userData['createdAt'],
        'updatedAt': userData['updatedAt'],
      };
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? username,
    String? email,
    String? phoneNumber,
    File? profilePhoto,
    Uint8List? profilePhotoBytes,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      print('Updating profile with:');
      print('Username: $username');
      print('Email: $email');
      print('Phone: $phoneNumber');
      print('Photo file: ${profilePhoto?.path}');
      print('Photo bytes: ${profilePhotoBytes?.length} bytes');

      // Use direct upload approach via update-profile endpoint
      // The backend userController handles profile photo upload directly
      final uri = Uri.parse('$baseUrl/update-profile');
      print('Request URL: $uri');

      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add text fields
      if (username != null && username.isNotEmpty) {
        request.fields['username'] = username;
      }
      if (email != null && email.isNotEmpty) {
        request.fields['email'] = email;
      }
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        request.fields['phoneNumber'] = phoneNumber;
      }

      // Add profile photo using the direct multipart approach (primary method)
      // The backend userController expects 'profilePhoto' field for the image
      if (kIsWeb && profilePhotoBytes != null) {
        print('Adding profile photo from bytes: ${profilePhotoBytes.length} bytes');
        final multipartFile = http.MultipartFile.fromBytes(
          'profilePhoto',
          profilePhotoBytes,
          filename: 'profile_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        request.files.add(multipartFile);
      } else if (!kIsWeb && profilePhoto != null) {
        print('Adding profile photo from file: ${profilePhoto.path}');
        final multipartFile = await http.MultipartFile.fromPath(
          'profilePhoto',
          profilePhoto.path,
        );
        request.files.add(multipartFile);
      }

      print('Sending profile update request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Update stored token with new user data
        if (data['token'] != null) {
          print('Updating stored token...');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', data['token']);
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Profile updated successfully',
        };
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'message': data['error'] ?? 'Update failed'};
      }
    } catch (e) {
      print('Error updating profile: $e');
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Upload profile photo using dedicated upload endpoint
  Future<Map<String, dynamic>> uploadProfilePhoto({
    File? profilePhoto,
    Uint8List? profilePhotoBytes,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      if (profilePhoto == null && profilePhotoBytes == null) {
        return {'success': false, 'message': 'No image provided'};
      }

      print('Uploading profile photo...');
      final uri = Uri.parse('${AppConfig.apiUrl}/upload/profilePhoto');
      print('Upload URL: $uri');

      final request = http.MultipartRequest('POST', uri);

      // Note: Upload endpoint doesn't require authentication based on backend routes

      // Add profile photo
      if (kIsWeb && profilePhotoBytes != null) {
        print('Adding profile photo from bytes: ${profilePhotoBytes.length} bytes');
        final multipartFile = http.MultipartFile.fromBytes(
          'image', // Backend expects 'image' field name
          profilePhotoBytes,
          filename: 'profile_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        request.files.add(multipartFile);
      } else if (!kIsWeb && profilePhoto != null) {
        print('Adding profile photo from file: ${profilePhoto.path}');
        final multipartFile = await http.MultipartFile.fromPath(
          'image', // Backend expects 'image' field name
          profilePhoto.path,
        );
        request.files.add(multipartFile);
      } else {
        return {'success': false, 'message': 'Invalid image data'};
      }

      print('Sending upload request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload response status: ${response.statusCode}');
      print('Upload response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'path': data['path'],
          'message': 'Image uploaded successfully',
        };
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'message': data['error'] ?? 'Upload failed'};
      }
    } catch (e) {
      print('Error uploading profile photo: $e');
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Get profile photo URL
  String? getProfilePhotoUrl(String? profilePhoto) {
    if (profilePhoto == null || profilePhoto.isEmpty) {
      print('No profile photo provided');
      return null;
    }
    if (profilePhoto.startsWith('http')) {
      print('Profile photo is already a full URL: $profilePhoto');
      return profilePhoto;
    }

    // Static files are served without the /api prefix
    // Backend serves static files from /public directory
    final baseUrl = AppConfig.apiUrl.replaceAll('/api', '');
    final fullUrl = '$baseUrl$profilePhoto';
    print('Generated profile photo URL: $fullUrl');
    return fullUrl;
  }

  // Test method to validate profile photo URL generation
  // Using example from backend uploads directory
  String getTestProfilePhotoUrl() {
    // Using one of the existing images from the backend
    final testImage = '/images/user/user-1750864413599.jpg';
    final baseUrl = AppConfig.apiUrl.replaceAll('/api', '');
    final fullUrl = '$baseUrl$testImage';
    print('Test profile photo URL: $fullUrl');
    return fullUrl;
  }
}
