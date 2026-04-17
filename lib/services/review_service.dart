import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:first_attempt/services/app_config.dart';
import 'package:first_attempt/services/auth_events.dart';
import 'package:first_attempt/services/token_store.dart';
import 'package:first_attempt/utils/logger.dart';

class ReviewUser {
  final String id;
  final String username;
  final String? profilePhoto;

  ReviewUser({required this.id, required this.username, this.profilePhoto});

  factory ReviewUser.fromJson(Map<String, dynamic> j) => ReviewUser(
        id: (j['_id'] ?? j['id'] ?? '').toString(),
        username: (j['username'] ?? '').toString(),
        profilePhoto: j['profilePhoto']?.toString(),
      );
}

class Review {
  final String id;
  final ReviewUser? user;
  final int rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    this.user,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> j) {
    final userField = j['user'];
    return Review(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      user: userField is Map<String, dynamic> ? ReviewUser.fromJson(userField) : null,
      rating: (j['rating'] is num) ? (j['rating'] as num).toInt() : 0,
      comment: (j['comment'] ?? '').toString(),
      createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class ReviewService {
  final String _baseUrl = '${AppConfig.apiUrl}/reviews';

  Future<String?> _token() => TokenStore.read();

  Future<List<Review>> listForStadium(String stadiumId) async {
    final token = await _token();
    final res = AuthEvents.observe(
      await http.get(
        Uri.parse('$_baseUrl/stadium/$stadiumId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );
    if (res.statusCode != 200) {
      AppLogger.warn('List reviews failed', meta: {'status': res.statusCode});
      throw _asError(res);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (data['data'] as List?) ?? [];
    return list.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Review> create({
    required String stadiumId,
    required int rating,
    required String comment,
  }) async {
    final token = await _token();
    final res = AuthEvents.observe(
      await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'stadiumId': stadiumId,
          'rating': rating,
          'comment': comment,
        }),
      ),
    );
    if (res.statusCode != 201 && res.statusCode != 200) throw _asError(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return Review.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String reviewId) async {
    final token = await _token();
    final res = AuthEvents.observe(
      await http.delete(
        Uri.parse('$_baseUrl/$reviewId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );
    if (res.statusCode != 200) throw _asError(res);
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
