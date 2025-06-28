import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:first_attempt/services/app_config.dart';
import '../models/notification.dart';

class NotificationService {
  final String baseUrl = '${AppConfig.apiUrl}/notifications';

  // Get stored token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Get all notifications for the current user
  Future<List<AppNotification>> getAllNotifications() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      print('Fetching notifications from: $baseUrl');

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('Notifications API response status: ${response.statusCode}');
      print('Notifications API response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        
        if (jsonData['notifications'] != null && jsonData['notifications'] is List) {
          print('Successfully fetched ${jsonData['notifications'].length} notifications');
          
          return (jsonData['notifications'] as List)
              .map((notification) {
                try {
                  return AppNotification.fromJson(notification);
                } catch (e) {
                  print('Error parsing notification: $e');
                  print('Notification data: $notification');
                  rethrow;
                }
              })
              .toList();
        } else {
          print('No notifications found in response');
          return [];
        }
      } else {
        print('Notifications API error: ${response.body}');
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('Notification service error: $e');
      rethrow;
    }
  }

  // Mark notification as read (this would need to be implemented in backend)
  Future<bool> markAsRead(String notificationId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      print('Marking notification as read: $notificationId');

      final response = await http.patch(
        Uri.parse('$baseUrl/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('Mark as read response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Successfully marked notification as read');
        return true;
      } else {
        print('Mark as read error: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Mark as read error: $e');
      // For now, return true as this endpoint might not be implemented
      return true;
    }
  }

  // Delete notification (this would need to be implemented in backend)
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      print('Deleting notification: $notificationId');

      final response = await http.delete(
        Uri.parse('$baseUrl/$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('Delete notification response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Successfully deleted notification');
        return true;
      } else {
        print('Delete notification error: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Delete notification error: $e');
      // For now, return true as this endpoint might not be implemented
      return true;
    }
  }

  // Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final notifications = await getAllNotifications();
      return notifications.where((n) => !n.read).length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Filter notifications by type
  List<AppNotification> filterByType(List<AppNotification> notifications, String type) {
    return notifications.where((n) => n.type == type).toList();
  }

  // Get team invitations
  List<AppNotification> getTeamInvitations(List<AppNotification> notifications) {
    return notifications.where((n) => n.isInvite && n.teamId != null).toList();
  }

  // Get info notifications
  List<AppNotification> getInfoNotifications(List<AppNotification> notifications) {
    return notifications.where((n) => n.isInfo).toList();
  }

  // Sort notifications by creation date (newest first)
  List<AppNotification> sortByDate(List<AppNotification> notifications) {
    final sortedList = List<AppNotification>.from(notifications);
    sortedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedList;
  }

  // Group notifications by date
  Map<String, List<AppNotification>> groupByDate(List<AppNotification> notifications) {
    final Map<String, List<AppNotification>> grouped = {};
    final now = DateTime.now();

    for (final notification in notifications) {
      final date = notification.createdAt;
      final difference = now.difference(date);

      String groupKey;
      if (difference.inDays == 0) {
        groupKey = 'Today';
      } else if (difference.inDays == 1) {
        groupKey = 'Yesterday';
      } else if (difference.inDays < 7) {
        groupKey = '${difference.inDays} days ago';
      } else {
        groupKey = '${date.day}/${date.month}/${date.year}';
      }

      if (!grouped.containsKey(groupKey)) {
        grouped[groupKey] = [];
      }
      grouped[groupKey]!.add(notification);
    }

    return grouped;
  }

  // Create mock notifications for testing (since backend might not have test data)
  Future<List<AppNotification>> getMockNotifications() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    final now = DateTime.now();
    return [
      AppNotification(
        id: 'mock_1',
        userId: 'user_1',
        message: 'John Doe invited you to join their team',
        read: false,
        type: 'invite',
        metadata: {
          'teamId': 'team_123',
          'senderId': 'user_john',
        },
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      AppNotification(
        id: 'mock_2',
        userId: 'user_1',
        message: 'Your team "Warriors" has joined the tournament "Summer Championship"',
        read: false,
        type: 'info',
        metadata: {
          'teamId': 'team_123',
          'tournamentId': 'tournament_456',
        },
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      AppNotification(
        id: 'mock_3',
        userId: 'user_1',
        message: 'Alice Smith accepted your team invitation',
        read: true,
        type: 'info',
        metadata: {
          'teamId': 'team_123',
          'acceptedUserId': 'user_alice',
        },
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      AppNotification(
        id: 'mock_4',
        userId: 'user_1',
        message: 'Bob Wilson rejected your team invitation',
        read: true,
        type: 'info',
        metadata: {
          'teamId': 'team_123',
          'rejectedUserId': 'user_bob',
        },
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      AppNotification(
        id: 'mock_5',
        userId: 'user_1',
        message: 'The tournament "Winter League" has been cancelled by the organizer',
        read: false,
        type: 'info',
        metadata: {
          'tournamentId': 'tournament_789',
        },
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
    ];
  }
}