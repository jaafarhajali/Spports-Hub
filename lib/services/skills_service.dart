import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:first_attempt/services/app_config.dart';
import 'package:first_attempt/services/auth_events.dart';
import 'package:first_attempt/services/token_store.dart';

class PlayerSkills {
  final String? position;       // goalkeeper | defender | midfielder | forward
  final int? skillLevel;        // 1..10
  final String? preferredFoot;  // left | right | both
  final String bio;

  PlayerSkills({
    this.position,
    this.skillLevel,
    this.preferredFoot,
    this.bio = '',
  });

  factory PlayerSkills.fromJson(Map<String, dynamic> j) => PlayerSkills(
        position: j['position']?.toString(),
        skillLevel: j['skillLevel'] is num ? (j['skillLevel'] as num).toInt() : null,
        preferredFoot: j['preferredFoot']?.toString(),
        bio: (j['bio'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'position': position,
        'skillLevel': skillLevel,
        'preferredFoot': preferredFoot,
        'bio': bio,
      };

  PlayerSkills copyWith({
    String? position,
    int? skillLevel,
    String? preferredFoot,
    String? bio,
    bool clearPosition = false,
    bool clearSkillLevel = false,
    bool clearPreferredFoot = false,
  }) {
    return PlayerSkills(
      position: clearPosition ? null : (position ?? this.position),
      skillLevel: clearSkillLevel ? null : (skillLevel ?? this.skillLevel),
      preferredFoot: clearPreferredFoot ? null : (preferredFoot ?? this.preferredFoot),
      bio: bio ?? this.bio,
    );
  }
}

class SkillsService {
  final String _baseUrl = '${AppConfig.apiUrl}/users/me/skills';

  Future<String?> _token() => TokenStore.read();

  Future<PlayerSkills> getMine() async {
    final token = await _token();
    final res = AuthEvents.observe(
      await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );
    if (res.statusCode != 200) throw _asError(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final payload = data['data'];
    if (payload is Map<String, dynamic>) return PlayerSkills.fromJson(payload);
    return PlayerSkills();
  }

  Future<PlayerSkills> update(PlayerSkills skills) async {
    final token = await _token();
    final res = AuthEvents.observe(
      await http.put(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(skills.toJson()),
      ),
    );
    if (res.statusCode != 200) throw _asError(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final payload = data['data'];
    if (payload is Map<String, dynamic>) {
      final s = payload['skills'];
      if (s is Map<String, dynamic>) return PlayerSkills.fromJson(s);
    }
    return skills;
  }

  Exception _asError(http.Response res) {
    try {
      final parsed = jsonDecode(res.body) as Map<String, dynamic>;
      final msg = parsed['error']?.toString() ?? parsed['message']?.toString();
      if (msg != null && msg.isNotEmpty) return Exception(msg);
    } catch (_) {}
    return Exception('Request failed (${res.statusCode})');
  }
}
