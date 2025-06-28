import 'dart:convert';
import 'package:first_attempt/services/app_config.dart';
import 'package:http/http.dart' as http;
import '../models/team.dart';
import '../auth_service.dart';

class TeamService {
  final String baseUrl = AppConfig.apiUrl;
  final AuthService _authService = AuthService();

  Future<Team> createTeam(String teamName) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Authentication required');
      }

      print('Creating team: $teamName');

      final response = await http
          .post(
            Uri.parse('$baseUrl/teams/create'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'name': teamName,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('Create team response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        print('Successfully created team: ${jsonData['message']}');
        
        // Update token if provided (user role changed to team leader)
        if (jsonData['token'] != null) {
          await _authService.saveToken(jsonData['token']);
        }
        
        if (jsonData['team'] != null) {
          return Team.fromJson(jsonData['team']);
        } else {
          throw Exception('Invalid team data received from server');
        }
      } else {
        final errorData = jsonDecode(response.body);
        print('Create team error: ${errorData['error']}');
        throw Exception(errorData['error'] ?? 'Failed to create team');
      }
    } catch (e) {
      print('Create team error: $e');
      rethrow;
    }
  }

  Future<List<TeamMember>> searchUsers({
    required String keyword,
    required String field,
  }) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Authentication required');
      }

      print('Searching users with keyword: $keyword, field: $field');

      final response = await http
          .get(
            Uri.parse('$baseUrl/teams/search?keyword=$keyword&field=$field'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('Search users response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('Successfully found ${jsonData['users'].length} users');
        
        return (jsonData['users'] as List)
            .map((user) => TeamMember.fromJson(user))
            .toList();
      } else if (response.statusCode == 404) {
        print('No users found');
        return [];
      } else {
        final errorData = jsonDecode(response.body);
        print('Search users error: ${errorData['error']}');
        throw Exception(errorData['error'] ?? 'Failed to search users');
      }
    } catch (e) {
      print('Search users error: $e');
      rethrow;
    }
  }

  Future<bool> inviteUser({
    required String userIdToInvite,
    required String teamId,
  }) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Authentication required');
      }

      print('Inviting user: $userIdToInvite to team: $teamId');

      final response = await http
          .post(
            Uri.parse('$baseUrl/teams/invite'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'userIdToInvite': userIdToInvite,
              'teamId': teamId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('Invite user response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('Successfully sent invitation: ${jsonData['message']}');
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        print('Invite user error: ${errorData['error']}');
        throw Exception(errorData['error'] ?? 'Failed to send invitation');
      }
    } catch (e) {
      print('Invite user error: $e');
      rethrow;
    }
  }

  Future<bool> acceptInvite({
    required String teamId,
    required String notificationId,
  }) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Authentication required');
      }

      print('Accepting invite for team: $teamId, notification: $notificationId');

      final response = await http
          .post(
            Uri.parse('$baseUrl/teams/accept'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'teamId': teamId,
              'notificationId': notificationId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('Accept invite response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('Successfully joined team: ${jsonData['message']}');
        
        // Update token if provided
        if (jsonData['token'] != null) {
          await _authService.saveToken(jsonData['token']);
        }
        
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        print('Accept invite error: ${errorData['error']}');
        throw Exception(errorData['error'] ?? 'Failed to accept invitation');
      }
    } catch (e) {
      print('Accept invite error: $e');
      rethrow;
    }
  }

  Future<bool> rejectInvite({
    required String notificationId,
  }) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Authentication required');
      }

      print('Rejecting invite with notification: $notificationId');

      final response = await http
          .post(
            Uri.parse('$baseUrl/teams/reject'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'notificationId': notificationId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('Reject invite response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('Successfully rejected invitation: ${jsonData['message']}');
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        print('Reject invite error: ${errorData['error']}');
        throw Exception(errorData['error'] ?? 'Failed to reject invitation');
      }
    } catch (e) {
      print('Reject invite error: $e');
      rethrow;
    }
  }

  Future<bool> removeMember({
    required String userIdToRemove,
    required String teamId,
  }) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Authentication required');
      }

      print('Removing member: $userIdToRemove from team: $teamId');

      final response = await http
          .post(
            Uri.parse('$baseUrl/teams/remove-member'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'userIdToRemove': userIdToRemove,
              'teamId': teamId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('Remove member response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('Successfully removed member: ${jsonData['message']}');
        
        // Update token if provided (removed user's token might be updated)
        if (jsonData['token'] != null) {
          await _authService.saveToken(jsonData['token']);
        }
        
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        print('Remove member error: ${errorData['error']}');
        throw Exception(errorData['error'] ?? 'Failed to remove member');
      }
    } catch (e) {
      print('Remove member error: $e');
      rethrow;
    }
  }

  Future<Team?> getMyTeam() async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Authentication required');
      }

      print('Getting my team');

      final response = await http
          .get(
            Uri.parse('$baseUrl/teams/my-team'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('Get my team response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['team'] != null) {
          print('Successfully retrieved team: ${jsonData['team']['name'] ?? 'Unknown'}');
          return Team.fromJson(jsonData['team']);
        } else {
          return null;
        }
      } else if (response.statusCode == 404) {
        print('User does not belong to any team');
        return null;
      } else {
        final errorData = jsonDecode(response.body);
        print('Get my team error: ${errorData['error']}');
        throw Exception(errorData['error'] ?? 'Failed to get team');
      }
    } catch (e) {
      print('Get my team error: $e');
      // Return null if team retrieval fails (user might not have a team)
      return null;
    }
  }

  Future<bool> deleteTeam() async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Authentication required');
      }

      print('Deleting team');

      final response = await http
          .post(
            Uri.parse('$baseUrl/teams/delete'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('Delete team response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('Successfully deleted team: ${jsonData['message']}');
        
        // Update token if provided (leader role reverted to user)
        if (jsonData['token'] != null) {
          await _authService.saveToken(jsonData['token']);
        }
        
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        print('Delete team error: ${errorData['error']}');
        throw Exception(errorData['error'] ?? 'Failed to delete team');
      }
    } catch (e) {
      print('Delete team error: $e');
      rethrow;
    }
  }

  Future<bool> exitTeam() async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Authentication required');
      }

      print('Exiting team');

      final response = await http
          .post(
            Uri.parse('$baseUrl/teams/exit'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('Exit team response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('Successfully exited team: ${jsonData['message']}');
        
        // Update token if provided
        if (jsonData['token'] != null) {
          await _authService.saveToken(jsonData['token']);
        }
        
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        print('Exit team error: ${errorData['error']}');
        throw Exception(errorData['error'] ?? 'Failed to exit team');
      }
    } catch (e) {
      print('Exit team error: $e');
      rethrow;
    }
  }
}