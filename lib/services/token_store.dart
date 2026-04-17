import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central token store.
///
/// Writes land in **flutter_secure_storage** (Android Keystore / iOS Keychain)
/// AND in SharedPreferences — the mirror lets older services that still read
/// `prefs.getString('auth_token')` keep working during the migration.
///
/// New code should read via [read] so tokens stored only in secure storage
/// still work. Eventually drop the SharedPreferences mirror.
class TokenStore {
  static const _key = 'auth_token';
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Save token to both stores.
  static Future<void> save(String token) async {
    await _secure.write(key: _key, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  /// Read token — prefers secure storage, falls back to prefs for old installs.
  static Future<String?> read() async {
    final secure = await _secure.read(key: _key);
    if (secure != null && secure.isNotEmpty) return secure;
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_key);
    // Auto-migrate: if we found a token only in prefs, copy to secure storage.
    if (legacy != null && legacy.isNotEmpty) {
      await _secure.write(key: _key, value: legacy);
    }
    return legacy;
  }

  /// Clear token from both stores.
  static Future<void> clear() async {
    await _secure.delete(key: _key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
