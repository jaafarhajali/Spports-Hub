import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:first_attempt/services/app_config.dart';
import 'package:first_attempt/services/auth_events.dart';
import 'package:first_attempt/services/token_store.dart';
import 'package:first_attempt/utils/logger.dart';

/// Pluggable AI client talking to /api/ai/* on the backend.
///
/// Every HTTP response goes through [AuthEvents.observe] — a 401 response
/// clears the token and fires a global logout signal which the app root
/// listens to for redirect-to-signin.
class AiService {
  final String _baseUrl = '${AppConfig.apiUrl}/ai';

  Future<String?> _token() => TokenStore.read();

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ─── Chatbot ───────────────────────────────────────────────
  Future<String> chat(List<Map<String, String>> messages) async {
    final token = await _token();
    final res = AuthEvents.observe(
      await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: _headers(token),
        body: jsonEncode({'messages': messages}),
      ),
    );
    if (res.statusCode != 200) {
      AppLogger.warn('AI chat failed', meta: {'status': res.statusCode});
      throw _asError(res);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['reply'] ?? '') as String;
  }

  // ─── NL stadium search ─────────────────────────────────────
  Future<Map<String, dynamic>> searchStadiums(String query) async {
    final token = await _token();
    final res = AuthEvents.observe(
      await http.post(
        Uri.parse('$_baseUrl/search-stadiums'),
        headers: _headers(token),
        body: jsonEncode({'query': query}),
      ),
    );
    if (res.statusCode != 200) {
      AppLogger.warn('AI search failed', meta: {'status': res.statusCode});
      throw _asError(res);
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── Description generator ─────────────────────────────────
  Future<String> generateDescription({
    required String type, // "stadium" | "academy"
    required String name,
    required String location,
    Map<String, dynamic>? extraFields,
  }) async {
    final token = await _token();
    final body = <String, dynamic>{
      'type': type,
      'name': name,
      'location': location,
      ...?extraFields,
    };
    final res = AuthEvents.observe(
      await http.post(
        Uri.parse('$_baseUrl/generate-description'),
        headers: _headers(token),
        body: jsonEncode(body),
      ),
    );
    if (res.statusCode != 200) throw _asError(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['description'] ?? '') as String;
  }

  // ─── Review summary ────────────────────────────────────────
  Future<Map<String, dynamic>?> reviewSummary(String stadiumId) async {
    final token = await _token();
    final res = AuthEvents.observe(
      await http.get(
        Uri.parse('$_baseUrl/review-summary/$stadiumId'),
        headers: _headers(token),
      ),
    );
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) throw _asError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── Bracket generation ────────────────────────────────────
  Future<Map<String, dynamic>> generateBracket(String tournamentId) async {
    final token = await _token();
    final res = AuthEvents.observe(
      await http.post(
        Uri.parse('$_baseUrl/generate-bracket'),
        headers: _headers(token),
        body: jsonEncode({'tournamentId': tournamentId}),
      ),
    );
    if (res.statusCode != 200) throw _asError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── Team member suggestions ───────────────────────────────
  Future<Map<String, dynamic>> suggestTeamMembers(String teamId) async {
    final token = await _token();
    final res = AuthEvents.observe(
      await http.post(
        Uri.parse('$_baseUrl/suggest-team-members'),
        headers: _headers(token),
        body: jsonEncode({'teamId': teamId}),
      ),
    );
    if (res.statusCode != 200) throw _asError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── Internal ──────────────────────────────────────────────
  Exception _asError(http.Response res) {
    try {
      final parsed = jsonDecode(res.body) as Map<String, dynamic>;
      final msg = parsed['error']?.toString() ?? parsed['message']?.toString();
      if (msg != null && msg.isNotEmpty) return Exception(msg);
    } catch (_) {
      // fall through
    }
    return Exception('Request failed (${res.statusCode})');
  }
}
