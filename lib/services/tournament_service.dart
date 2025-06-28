import 'dart:convert';
import 'package:first_attempt/services/app_config.dart';
import 'package:http/http.dart' as http;
import '../models/tournament.dart';
import '../auth_service.dart';

class TournamentService {
  final String baseUrl = AppConfig.apiUrl;
  final AuthService _authService = AuthService();

  // ============================================================================
  // PUBLIC TOURNAMENT ENDPOINTS (/api/tournaments)
  // ============================================================================

  /// Get all tournaments - Available to any authenticated user
  /// GET /api/tournaments/
  Future<List<Tournament>> getAllTournaments({
    String? status,
    String? sport,
    double? minPrize,
    double? maxPrize,
    String? search,
    int? maxTeams,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Authentication required');
      }

      // Build query parameters
      final queryParams = <String, String>{};
      if (status != null && status != 'All') queryParams['status'] = status;
      if (sport != null && sport != 'All Sports') queryParams['sport'] = sport;
      if (minPrize != null) queryParams['minPrize'] = minPrize.toString();
      if (maxPrize != null) queryParams['maxPrize'] = maxPrize.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (maxTeams != null) queryParams['maxTeams'] = maxTeams.toString();
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final uri = Uri.parse('$baseUrl/tournaments').replace(queryParameters: queryParams);
      
      print('Fetching tournaments from: $uri');

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('Tournament API response status: ${response.statusCode}');
      print('Tournament API response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        // Backend returns: {"status": "success", "data": [...]}
        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          print('Successfully fetched ${jsonData['data'].length} tournaments');
          
          return (jsonData['data'] as List)
              .map((tournamentJson) {
                try {
                  return Tournament.fromJson(tournamentJson);
                } catch (e) {
                  print('Error parsing tournament: $e');
                  print('Tournament data: $tournamentJson');
                  rethrow;
                }
              })
              .toList();
        } else {
          print('API returned status != success or no data');
          return [];
        }
      } else {
        print('Tournament API error: ${response.body}');
        throw Exception('Failed to load tournaments: ${response.statusCode}');
      }
    } catch (e) {
      print('Tournament service error: $e');
      // Fall back to mock data for development
      print('Falling back to mock data for development');
      return await getMockTournaments();
    }
  }

  /// Join tournament with team - Requires teamLeader role
  /// POST /api/tournaments/join
  Future<Map<String, dynamic>> joinTournament(String tournamentId, String teamId) async {
    try {
      final token = await _authService.getToken();
      final userRole = await _authService.getUserRole();

      if (token == null) {
        throw Exception('Authentication required');
      }

      // Check if user has teamLeader role (as per backend requirement)
      if (userRole != 'teamLeader' && userRole != 'admin') {
        throw Exception('Only team leaders can join tournaments');
      }

      print('Joining tournament: $tournamentId with team: $teamId');

      final response = await http
          .post(
            Uri.parse('$baseUrl/tournaments/join'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'tournamentId': tournamentId,
              'teamId': teamId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('Join tournament response status: ${response.statusCode}');
      print('Join tournament response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'success') {
          return {
            'success': true,
            'message': jsonData['message'] ?? 'Successfully joined tournament',
            'data': jsonData['data'],
          };
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to join tournament');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to join tournament');
      }
    } catch (e) {
      print('Join tournament error: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // ============================================================================
  // DASHBOARD TOURNAMENT ENDPOINTS (/api/dashboard)
  // ============================================================================

  /// Get all tournaments (admin view) - Requires admin role
  /// GET /api/dashboard/tournaments
  Future<List<Tournament>> getAllTournamentsForAdmin() async {
    try {
      final token = await _authService.getToken();
      final userRole = await _authService.getUserRole();

      if (token == null) {
        throw Exception('Authentication required');
      }

      if (userRole != 'admin') {
        throw Exception('Admin access required');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/tournaments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          return (jsonData['data'] as List)
              .map((tournament) => Tournament.fromJson(tournament))
              .toList();
        }
      }
      
      throw Exception('Failed to load admin tournaments');
    } catch (e) {
      print('Get admin tournaments error: $e');
      rethrow;
    }
  }

  /// Get tournaments created by current user - Requires stadiumOwner role
  /// GET /api/dashboard/my-tournaments
  Future<List<Tournament>> getMyTournaments() async {
    try {
      final token = await _authService.getToken();
      final userRole = await _authService.getUserRole();

      if (token == null) {
        throw Exception('Authentication required');
      }

      if (userRole != 'stadiumOwner' && userRole != 'admin') {
        throw Exception('Stadium owner access required');
      }

      print('Fetching my tournaments');

      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/my-tournaments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get my tournaments response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          print('Successfully fetched ${jsonData['data'].length} my tournaments');
          return (jsonData['data'] as List)
              .map((tournament) => Tournament.fromJson(tournament))
              .toList();
        } else {
          return [];
        }
      } else if (response.statusCode == 404) {
        print('No tournaments found');
        return [];
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to get my tournaments');
      }
    } catch (e) {
      print('Get my tournaments error: $e');
      return [];
    }
  }

  /// Create new tournament - Requires stadiumOwner role
  /// POST /api/dashboard/tournaments
  Future<Tournament> createTournament({
    required String name,
    required String description,
    required double entryPricePerTeam,
    required double rewardPrize,
    required int maxTeams,
    required DateTime startDate,
    required DateTime endDate,
    required String stadiumId,
  }) async {
    try {
      final token = await _authService.getToken();
      final userRole = await _authService.getUserRole();

      if (token == null) {
        throw Exception('Authentication required');
      }

      // Check if user has stadiumOwner role (as per backend requirement)
      if (userRole != 'stadiumOwner' && userRole != 'admin') {
        throw Exception('Only stadium owners can create tournaments');
      }

      print('Creating tournament: $name at stadium: $stadiumId');

      final requestBody = {
        'name': name,
        'description': description,
        'entryPricePerTeam': entryPricePerTeam,
        'rewardPrize': rewardPrize,
        'maxTeams': maxTeams,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'stadiumId': stadiumId,
      };

      print('Request body: ${jsonEncode(requestBody)}');

      final response = await http
          .post(
            Uri.parse('$baseUrl/dashboard/tournaments'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      print('Create tournament response status: ${response.statusCode}');
      print('Create tournament response body: ${response.body}');

      if (response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          print('Successfully created tournament');
          return Tournament.fromJson(jsonData['data']);
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to create tournament');
        }
      } else {
        final errorData = jsonDecode(response.body);
        print('Create tournament error: ${errorData['message']}');
        throw Exception(errorData['message'] ?? 'Failed to create tournament');
      }
    } catch (e) {
      print('Create tournament error: $e');
      rethrow;
    }
  }

  /// Update tournament - Requires ownership (createdBy)
  /// PUT /api/dashboard/tournaments/:id
  Future<Tournament> updateTournament({
    required String tournamentId,
    String? name,
    String? description,
    double? entryPricePerTeam,
    double? rewardPrize,
    int? maxTeams,
    DateTime? startDate,
    DateTime? endDate,
    String? stadiumId,
  }) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Authentication required');
      }

      print('Updating tournament: $tournamentId');

      final requestBody = <String, dynamic>{};
      if (name != null) requestBody['name'] = name;
      if (description != null) requestBody['description'] = description;
      if (entryPricePerTeam != null) requestBody['entryPricePerTeam'] = entryPricePerTeam;
      if (rewardPrize != null) requestBody['rewardPrize'] = rewardPrize;
      if (maxTeams != null) requestBody['maxTeams'] = maxTeams;
      if (startDate != null) requestBody['startDate'] = startDate.toIso8601String();
      if (endDate != null) requestBody['endDate'] = endDate.toIso8601String();
      if (stadiumId != null) requestBody['stadiumId'] = stadiumId;

      final response = await http.put(
        Uri.parse('$baseUrl/dashboard/tournaments/$tournamentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          return Tournament.fromJson(jsonData['data']);
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to update tournament');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update tournament');
      }
    } catch (e) {
      print('Update tournament error: $e');
      rethrow;
    }
  }

  /// Delete tournament - Requires ownership (createdBy)
  /// DELETE /api/dashboard/tournaments/:id
  Future<bool> deleteTournament(String tournamentId) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Authentication required');
      }

      print('Deleting tournament: $tournamentId');

      final response = await http.delete(
        Uri.parse('$baseUrl/dashboard/tournaments/$tournamentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'success') {
          print('Successfully deleted tournament');
          return true;
        }
      }
      
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to delete tournament');
    } catch (e) {
      print('Delete tournament error: $e');
      return false;
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Check if user can create tournaments (stadiumOwner or admin role)
  Future<bool> canCreateTournaments() async {
    try {
      final userRole = await _authService.getUserRole();
      return userRole == 'stadiumOwner' || userRole == 'admin';
    } catch (e) {
      return false;
    }
  }

  /// Check if user can join tournaments (teamLeader or admin role)
  Future<bool> canJoinTournaments() async {
    try {
      final userRole = await _authService.getUserRole();
      return userRole == 'teamLeader' || userRole == 'admin';
    } catch (e) {
      return false;
    }
  }

  /// Filter tournaments by status
  List<Tournament> filterTournaments(List<Tournament> tournaments, String filter) {
    switch (filter) {
      case 'Upcoming':
        return tournaments.where((t) => t.isRegistrationOpen).toList();
      case 'Ongoing':
        return tournaments.where((t) => t.isOngoing).toList();
      case 'Past':
        return tournaments.where((t) => t.isPast).toList();
      case 'My Tournaments':
        return tournaments;
      case 'All':
      default:
        return tournaments;
    }
  }

  /// Mock tournaments for development/testing
  Future<List<Tournament>> getMockTournaments() async {
    await Future.delayed(const Duration(seconds: 1));

    return [
      Tournament(
        id: '1',
        name: 'Summer Football Championship',
        description: 'Annual summer football tournament featuring the best teams from across the city.',
        entryPricePerTeam: 100.0,
        rewardPrize: 2000.0,
        teams: ['team1', 'team2', 'team3'],
        maxTeams: 32,
        startDate: DateTime(2025, 5, 25),
        endDate: DateTime(2025, 6, 10),
        createdBy: 'user1',
        stadiumId: 'stadium1',
        stadiumName: 'City Sports Arena',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Tournament(
        id: '2',
        name: 'Basketball All-Stars',
        description: 'Elite basketball tournament for professional teams.',
        entryPricePerTeam: 80.0,
        rewardPrize: 1500.0,
        teams: ['team4', 'team5'],
        maxTeams: 16,
        startDate: DateTime(2025, 6, 15),
        endDate: DateTime(2025, 6, 20),
        createdBy: 'user2',
        stadiumId: 'stadium2',
        stadiumName: 'Central Basketball Court',
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Tournament(
        id: '3',
        name: 'Tennis Open Tournament',
        description: 'Open tennis tournament for players of all skill levels.',
        entryPricePerTeam: 50.0,
        rewardPrize: 1000.0,
        teams: [],
        maxTeams: 64,
        startDate: DateTime(2025, 7, 1),
        endDate: DateTime(2025, 7, 7),
        createdBy: 'user3',
        stadiumId: 'stadium3',
        stadiumName: 'Green Park Tennis Courts',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}