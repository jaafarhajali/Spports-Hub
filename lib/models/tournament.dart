class Tournament {
  final String id;
  final String name;
  final String description;
  final double entryPricePerTeam;
  final double rewardPrize;
  final List<String> teams;
  final int maxTeams;
  final DateTime startDate;
  final DateTime endDate;
  final String createdBy;
  final String stadiumId;
  final String? stadiumName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? updatedBy;

  Tournament({
    required this.id,
    required this.name,
    required this.description,
    required this.entryPricePerTeam,
    required this.rewardPrize,
    required this.teams,
    required this.maxTeams,
    required this.startDate,
    required this.endDate,
    required this.createdBy,
    required this.stadiumId,
    this.stadiumName,
    required this.createdAt,
    required this.updatedAt,
    this.updatedBy,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    try {
      // Helper function to safely extract string from object or string  
      String extractId(dynamic value) {
        if (value is Map<String, dynamic>) {
          return value['_id']?.toString() ?? '';
        }
        return value?.toString() ?? '';
      }

      // Helper function to safely extract name from object
      String? extractName(dynamic value) {
        if (value is Map<String, dynamic>) {
          return value['name']?.toString();
        }
        return null;
      }

      // Helper function to safely extract username from populated createdBy
      String extractCreatedBy(dynamic value) {
        if (value is Map<String, dynamic>) {
          return value['username']?.toString() ?? value['_id']?.toString() ?? '';
        }
        return value?.toString() ?? '';
      }

      // Helper function to safely parse teams list - backend populates with team objects
      List<String> parseTeams(dynamic teamsData) {
        if (teamsData is List) {
          return teamsData.map((item) {
            if (item is Map<String, dynamic>) {
              return item['_id']?.toString() ?? '';
            }
            return item?.toString() ?? '';
          }).where((id) => id.isNotEmpty).toList();
        }
        return [];
      }

      return Tournament(
        id: json['_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        entryPricePerTeam: (json['entryPricePerTeam'] ?? 0).toDouble(),
        rewardPrize: (json['rewardPrize'] ?? 0).toDouble(),
        teams: parseTeams(json['teams']),
        maxTeams: json['maxTeams'] ?? 0,
        startDate: DateTime.tryParse(json['startDate']) ?? DateTime.now(),
        endDate: DateTime.tryParse(json['endDate']) ?? DateTime.now().add(const Duration(days: 1)),
        createdBy: extractCreatedBy(json['createdBy']),
        stadiumId: extractId(json['stadiumId']),
        stadiumName: extractName(json['stadiumId']),
        createdAt: DateTime.tryParse(json['createdAt']) ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt']) ?? DateTime.now(),
        updatedBy: json['updatedBy']?.toString(),
      );
    } catch (e) {
      print('Error parsing tournament JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'entryPricePerTeam': entryPricePerTeam,
      'rewardPrize': rewardPrize,
      'teams': teams,
      'maxTeams': maxTeams,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'createdBy': createdBy,
      'stadiumId': stadiumId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'updatedBy': updatedBy,
    };
  }

  String get formattedDateRange {
    if (startDate.year == endDate.year && 
        startDate.month == endDate.month && 
        startDate.day == endDate.day) {
      return _formatDate(startDate);
    }
    return '${_formatDate(startDate)} - ${_formatDate(endDate)}';
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  bool get isRegistrationOpen {
    final now = DateTime.now();
    return now.isBefore(startDate) && teams.length < maxTeams;
  }

  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  bool get isPast {
    final now = DateTime.now();
    return now.isAfter(endDate);
  }

  String get status {
    if (isPast) return 'Completed';
    if (isOngoing) return 'Ongoing';
    if (teams.length >= maxTeams) return 'Full';
    return '${teams.length}/$maxTeams teams registered';
  }
}