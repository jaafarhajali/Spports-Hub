// lib/services/booking_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth_service.dart';
import 'app_config.dart';

class BookingService {
  final String baseUrl = AppConfig.apiUrl;
  final AuthService _authService = AuthService();

  // Create a new booking
  Future<Map<String, dynamic>> createBooking({
    required String stadiumId,
    required DateTime matchDate,
    required String timeSlot,
    String? refereeId,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/bookings/book'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'stadiumId': stadiumId,
          'matchDate': matchDate.toIso8601String(),
          'timeSlot': timeSlot,
          if (refereeId != null) 'refereeId': refereeId,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'],
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create booking',
        };
      }
    } catch (e) {
      print('Create booking error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get user's bookings
  Future<Map<String, dynamic>> getUserBookings() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/bookings/my-bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'count': responseData['count'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to load bookings',
        };
      }
    } catch (e) {
      print('Get user bookings error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Cancel a booking
  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'],
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to cancel booking',
        };
      }
    } catch (e) {
      print('Cancel booking error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
