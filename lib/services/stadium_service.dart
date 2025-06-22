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
        ownerId: 'owner1',
        name: 'City Football Stadium',
        location: 'Downtown Central Park',
        photos: [
          'https://images.unsplash.com/photo-1594470117722-de4b9a02ebed',
        ],
        pricePerMatch: 50000.0,
        maxPlayers: 22,
        workingHours: {'start': '10:00', 'end': '22:00'},
        penaltyPolicy: {'hoursBefore': 2, 'penaltyAmount': 10000},
        calendar: [
          // Today - mixed availability
          CalendarEntry(
            date: DateTime.now(),
            slots: [
              SlotModel(startTime: '10:00', endTime: '11:00', isBooked: false),
              SlotModel(startTime: '11:00', endTime: '12:00', isBooked: true),
              SlotModel(startTime: '12:00', endTime: '13:00', isBooked: false),
              SlotModel(startTime: '14:00', endTime: '15:00', isBooked: false),
              SlotModel(startTime: '15:00', endTime: '16:00', isBooked: true),
              SlotModel(startTime: '16:00', endTime: '17:00', isBooked: false),
              SlotModel(startTime: '18:00', endTime: '19:00', isBooked: false),
              SlotModel(startTime: '20:00', endTime: '21:00', isBooked: false),
            ],
          ),
          // Tomorrow - different availability pattern
          CalendarEntry(
            date: DateTime.now().add(const Duration(days: 1)),
            slots: [
              SlotModel(startTime: '10:00', endTime: '11:00', isBooked: false),
              SlotModel(startTime: '11:00', endTime: '12:00', isBooked: false),
              SlotModel(startTime: '13:00', endTime: '14:00', isBooked: false),
              SlotModel(startTime: '15:00', endTime: '16:00', isBooked: false),
              SlotModel(startTime: '17:00', endTime: '18:00', isBooked: true),
              SlotModel(startTime: '19:00', endTime: '20:00', isBooked: false),
            ],
          ),
          // Day 2 - fully booked day
          CalendarEntry(
            date: DateTime.now().add(const Duration(days: 2)),
            slots: [
              SlotModel(startTime: '10:00', endTime: '11:00', isBooked: true),
              SlotModel(startTime: '11:00', endTime: '12:00', isBooked: true),
              SlotModel(startTime: '12:00', endTime: '13:00', isBooked: true),
              SlotModel(startTime: '14:00', endTime: '15:00', isBooked: true),
              SlotModel(startTime: '15:00', endTime: '16:00', isBooked: true),
              SlotModel(startTime: '16:00', endTime: '17:00', isBooked: true),
            ],
          ),
          // Day 3 - mostly available
          CalendarEntry(
            date: DateTime.now().add(const Duration(days: 3)),
            slots: [
              SlotModel(startTime: '10:00', endTime: '11:00', isBooked: false),
              SlotModel(startTime: '11:00', endTime: '12:00', isBooked: false),
              SlotModel(startTime: '12:00', endTime: '13:00', isBooked: false),
              SlotModel(startTime: '14:00', endTime: '15:00', isBooked: false),
              SlotModel(startTime: '15:00', endTime: '16:00', isBooked: false),
              SlotModel(startTime: '16:00', endTime: '17:00', isBooked: false),
              SlotModel(startTime: '18:00', endTime: '19:00', isBooked: false),
              SlotModel(startTime: '19:00', endTime: '20:00', isBooked: false),
              SlotModel(startTime: '20:00', endTime: '21:00', isBooked: false),
            ],
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        owner: {'username': 'StadiumOwner1', 'email': 'owner1@example.com'},
      ),
      Stadium(
        id: '2',
        ownerId: 'owner2',
        name: 'Olympic Basketball Court',
        location: 'Sports Village, East Side',
        photos: ['https://images.unsplash.com/photo-1546519638-68e109498ffc'],
        pricePerMatch: 35000.0,
        maxPlayers: 10,
        workingHours: {'start': '09:00', 'end': '20:00'},
        penaltyPolicy: {'hoursBefore': 3, 'penaltyAmount': 15000},
        calendar: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        owner: {'username': 'StadiumOwner2', 'email': 'owner2@example.com'},
      ),
      Stadium(
        id: '3',
        ownerId: 'owner3',
        name: 'Green Park Tennis Club',
        location: 'Westside Gardens',
        photos: [
          'https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0',
        ],
        pricePerMatch: 25000.0,
        maxPlayers: 4,
        workingHours: {'start': '08:00', 'end': '19:00'},
        penaltyPolicy: {'hoursBefore': 4, 'penaltyAmount': 20000},
        calendar: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        owner: {'username': 'StadiumOwner3', 'email': 'owner3@example.com'},
      ),
    ];
  }
}
