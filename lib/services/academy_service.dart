// lib/services/academy_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/academy.dart';
import '../auth_service.dart';
import '../services/app_config.dart';

class AcademyService {
  final String baseUrl = AppConfig.apiUrl; // Match your backend URL
  final AuthService _authService = AuthService();

  // Get all academies
  Future<List<Academy>> getAcademies() async {
    try {
      // Get authentication token
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Authentication required');
      }

      print('Fetching academies from: $baseUrl/academies');

      final response = await http
          .get(
            Uri.parse('$baseUrl/academies'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('Academy API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          print('Successfully fetched ${jsonData['count']} academies');

          return (jsonData['data'] as List)
              .map((academy) => Academy.fromJson(academy))
              .toList();
        } else {
          print('API returned success=false or no data');
          return [];
        }
      } else {
        print('Academy API error: ${response.body}');
        throw Exception('Failed to load academies: ${response.statusCode}');
      }
    } catch (e) {
      print('Academy service error: $e');
      rethrow; // Re-throw to let the UI handle it
    }
  }

  // Get academy details by ID
  Future<Academy> getAcademyById(String id) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/academies/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          return Academy.fromJson(jsonData['data']);
        } else {
          throw Exception('Academy not found');
        }
      } else {
        throw Exception('Failed to load academy details');
      }
    } catch (e) {
      print('Get academy by ID error: $e');
      rethrow;
    }
  }

  // Create new academy
  Future<Academy> createAcademy({
    required String name,
    required String description,
    required String location,
    required String phoneNumber,
    required String email,
    List<File>? photos,
  }) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Authentication required');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/dashboard/academies'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['location'] = location;
      request.fields['phoneNumber'] = phoneNumber;
      request.fields['email'] = email;

      if (photos != null && photos.isNotEmpty) {
        for (int i = 0; i < photos.length && i < 5; i++) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'photos',
              photos[i].path,
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return Academy.fromJson(jsonData['data']);
        } else {
          throw Exception('Failed to create academy');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create academy');
      }
    } catch (e) {
      print('Create academy error: $e');
      rethrow;
    }
  }

  // Update academy
  Future<Academy> updateAcademy({
    required String academyId,
    required String name,
    required String description,
    required String location,
    required String phoneNumber,
    required String email,
    List<File>? photos,
  }) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Authentication required');
      }

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/dashboard/academies/$academyId'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['location'] = location;
      request.fields['phoneNumber'] = phoneNumber;
      request.fields['email'] = email;

      if (photos != null && photos.isNotEmpty) {
        for (int i = 0; i < photos.length && i < 5; i++) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'photos',
              photos[i].path,
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return Academy.fromJson(jsonData['data']);
        } else {
          throw Exception('Failed to update academy');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update academy');
      }
    } catch (e) {
      print('Update academy error: $e');
      rethrow;
    }
  }

  // Delete academy
  Future<bool> deleteAcademy(String academyId) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/dashboard/academies/$academyId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData['success'] == true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete academy');
      }
    } catch (e) {
      print('Delete academy error: $e');
      rethrow;
    }
  }

  // Get academies by owner
  Future<List<Academy>> getMyAcademies() async {
    try {
      final token = await _authService.getToken();
      final userId = await _authService.getUserId();

      if (token == null || userId == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/my-academies'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return (jsonData['data'] as List)
              .map((academy) => Academy.fromJson(academy))
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load my academies');
      }
    } catch (e) {
      print('Get my academies error: $e');
      return [];
    }
  }

  // Check if user can create academies (only academyOwner and admin)
  Future<bool> canCreateAcademies() async {
    try {
      final userRole = await _authService.getUserRole();
      return userRole == 'academyOwner' || userRole == 'admin';
    } catch (e) {
      return false;
    }
  }

  // Check if user can edit/delete a specific academy (only owner or admin)
  Future<bool> canEditAcademy(Academy academy) async {
    try {
      final userRole = await _authService.getUserRole();
      final userId = await _authService.getUserId();
      
      // Admin can edit any academy
      if (userRole == 'admin') {
        return true;
      }
      
      // Academy owner can only edit their own academies
      if (userRole == 'academyOwner' && academy.owner['_id'] == userId) {
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Helper method to get mock academies for testing
  Future<List<Academy>> getMockAcademies() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    return [
      Academy(
        id: '1',
        name: 'Elite Football Academy',
        description: 'Professional football training for all skill levels',
        location: 'Downtown Sports Complex',
        sports: ['Football', 'Soccer'],
        photos: [
          'https://images.unsplash.com/photo-1431324155629-1a6deb1dec8d',
        ],
        rating: 4.8,
        ageGroup: '8-18 years',
        contact: {'phone': '+1234567890', 'email': 'info@elitefootball.com'},
        owner: {'username': 'Coach Smith', 'email': 'smith@example.com'},
        createdAt: DateTime.now(),
      ),
      Academy(
        id: '2',
        name: 'Champions Basketball Academy',
        description: 'Develop your basketball skills with professional coaches',
        location: 'City Basketball Center',
        sports: ['Basketball'],
        photos: ['https://images.unsplash.com/photo-1546519638-68e109498ffc'],
        rating: 4.6,
        ageGroup: '10-20 years',
        contact: {
          'phone': '+1234567891',
          'email': 'info@championsbasketball.com',
        },
        owner: {'username': 'Coach Johnson', 'email': 'johnson@example.com'},
        createdAt: DateTime.now(),
      ),
      Academy(
        id: '3',
        name: 'Tennis Pro Academy',
        description: 'Master tennis techniques with certified instructors',
        location: 'Green Valley Tennis Club',
        sports: ['Tennis'],
        photos: [
          'https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0',
        ],
        rating: 4.7,
        ageGroup: '6-25 years',
        contact: {'phone': '+1234567892', 'email': 'info@tennispro.com'},
        owner: {'username': 'Coach Williams', 'email': 'williams@example.com'},
        createdAt: DateTime.now(),
      ),
      Academy(
        id: '4',
        name: 'Swimming Excellence Academy',
        description: 'Learn swimming from beginner to competitive levels',
        location: 'Olympic Aquatic Center',
        sports: ['Swimming'],
        photos: [
          'https://images.unsplash.com/photo-1530549387789-4c1017266635',
        ],
        rating: 4.9,
        ageGroup: '5-30 years',
        contact: {'phone': '+1234567893', 'email': 'info@swimexcellence.com'},
        owner: {'username': 'Coach Davis', 'email': 'davis@example.com'},
        createdAt: DateTime.now(),
      ),
    ];
  }
}
