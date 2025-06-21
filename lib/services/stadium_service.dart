// lib/services/stadium_service.dart
import 'dart:convert';
import 'package:first_attempt/services/app_config.dart';
import 'package:http/http.dart' as http;
import '../models/stadium.dart';
import '../auth_service.dart';

class StadiumService {
  final String baseUrl = AppConfig.apiUrl;
  
  final AuthService _authService = AuthService();

  // Get all stadiums
  Future<List<Stadium>> getStadiums() async {
    try {
      // Get authentication token
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Authentication required');
      }

      print('Fetching stadiums from: $baseUrl/stadiums');

      final response = await http
          .get(
            Uri.parse('$baseUrl/stadiums'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('Stadium API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          print('Successfully fetched ${jsonData['count']} stadiums');

          return (jsonData['data'] as List)
              .map((stadium) => Stadium.fromJson(stadium))
              .toList();
        } else {
          print('API returned success=false or no data');
          return [];
        }
      } else {
        print('Stadium API error: ${response.body}');
        throw Exception('Failed to load stadiums: ${response.statusCode}');
      }
    } catch (e) {
      print('Stadium service error: $e');
      rethrow; // Re-throw to let the UI handle it
    }
  }

  // Get stadium details by ID
  Future<Stadium> getStadiumById(String id) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/stadiums/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          return Stadium.fromJson(jsonData['data']);
        } else {
          throw Exception('Stadium not found');
        }
      } else {
        throw Exception('Failed to load stadium details');
      }
    } catch (e) {
      print('Get stadium by ID error: $e');
      rethrow;
    }
  }

  // Helper method to get mock stadiums for testing
  Future<List<Stadium>> getMockStadiums() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    return [
      Stadium(
        id: '1',
        name: 'City Football Stadium',
        location: 'Downtown Central Park',
        photos: [
          'https://images.unsplash.com/photo-1594470117722-de4b9a02ebed',
        ],
        pricePerHour: 50.0,
        workingHours: {'start': '10:00', 'end': '22:00'},
        penaltyPolicy: {'hoursBefore': 2, 'penaltyAmount': 10},
        owner: {'username': 'StadiumOwner1', 'email': 'owner1@example.com'},
        createdAt: DateTime.now(),
      ),
      Stadium(
        id: '2',
        name: 'Olympic Basketball Court',
        location: 'Sports Village, East Side',
        photos: ['https://images.unsplash.com/photo-1546519638-68e109498ffc'],
        pricePerHour: 35.0,
        workingHours: {'start': '09:00', 'end': '20:00'},
        penaltyPolicy: {'hoursBefore': 3, 'penaltyAmount': 15},
        owner: {'username': 'StadiumOwner2', 'email': 'owner2@example.com'},
        createdAt: DateTime.now(),
      ),
      Stadium(
        id: '3',
        name: 'Green Park Tennis Club',
        location: 'Westside Gardens',
        photos: [
          'https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0',
        ],
        pricePerHour: 40.0,
        workingHours: {'start': '08:00', 'end': '19:00'},
        penaltyPolicy: {'hoursBefore': 4, 'penaltyAmount': 20},
        owner: {'username': 'StadiumOwner3', 'email': 'owner3@example.com'},
        createdAt: DateTime.now(),
      ),
    ];
  }
}
