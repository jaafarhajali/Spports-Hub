import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:first_attempt/services/token_store.dart';

/// Global auth-expired signal. The app root listens to [loggedOut] and
/// redirects to the sign-in screen when it fires.
///
/// Any service that makes an authenticated request should wrap the response
/// with `AuthEvents.observe(response)` — if it's a 401 we clear the token
/// and notify listeners. Returns the same response unchanged.
class AuthEvents {
  static final ValueNotifier<int> loggedOut = ValueNotifier<int>(0);

  /// Pass through the response after checking for 401.
  /// Usage:  final res = AuthEvents.observe(await http.get(...));
  static http.Response observe(http.Response response) {
    if (response.statusCode == 401) {
      _triggerLogout();
    }
    return response;
  }

  /// Call explicitly when you want to force a logout (e.g. from a catch block).
  static Future<void> forceLogout() async {
    await _triggerLogout();
  }

  static Future<void> _triggerLogout() async {
    await TokenStore.clear();
    // Increment to trigger listeners; ValueNotifier only fires on value change.
    loggedOut.value = loggedOut.value + 1;
  }
}
