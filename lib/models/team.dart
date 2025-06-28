class Team {
  final String id;
  final String name;
  final String leader;
  final List<TeamMember> members;
  final String? createdBy;
  final DateTime createdAt;

  Team({
    required this.id,
    required this.name,
    required this.leader,
    required this.members,
    this.createdBy,
    required this.createdAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    try {
      // Helper function to safely extract leader ID
      String extractLeaderId(dynamic value) {
        if (value is Map<String, dynamic>) {
          return value['_id']?.toString() ?? '';
        }
        return value?.toString() ?? '';
      }

      // Helper function to safely parse members list
      List<TeamMember> parseMembers(dynamic membersData) {
        if (membersData is List) {
          return membersData.map((member) {
            try {
              if (member is Map<String, dynamic>) {
                return TeamMember.fromJson(member);
              }
              return null;
            } catch (e) {
              print('Error parsing team member: $e');
              return null;
            }
          }).where((member) => member != null).cast<TeamMember>().toList();
        }
        return [];
      }

      return Team(
        id: json['_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        leader: extractLeaderId(json['leader']),
        members: parseMembers(json['members']),
        createdBy: json['createdBy']?.toString(),
        createdAt: DateTime.tryParse(json['createdAt']) ?? DateTime.now(),
      );
    } catch (e) {
      print('Error parsing team JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'leader': leader,
      'members': members.map((member) => member.toJson()).toList(),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  int get memberCount => members.length;

  List<TeamMember> get nonLeaderMembers => 
      members.where((member) => member.id != leader).toList();

  TeamMember? get leaderMember {
    final leaderMembers = members.where((member) => member.id == leader);
    return leaderMembers.isNotEmpty ? leaderMembers.first : null;
  }
}

class TeamMember {
  final String id;
  final String username;
  final String email;
  final String phoneNumber;
  final UserRole? role;

  TeamMember({
    required this.id,
    required this.username,
    required this.email,
    required this.phoneNumber,
    this.role,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    try {
      // Helper function to safely parse role
      UserRole? parseRole(dynamic roleData) {
        if (roleData is Map<String, dynamic>) {
          return UserRole.fromJson(roleData);
        }
        return null;
      }

      return TeamMember(
        id: json['_id']?.toString() ?? '',
        username: json['username']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        phoneNumber: json['phoneNumber']?.toString() ?? '',
        role: parseRole(json['role']),
      );
    } catch (e) {
      print('Error parsing team member JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role?.toJson(),
    };
  }
}

class UserRole {
  final String id;
  final String name;

  UserRole({
    required this.id,
    required this.name,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}