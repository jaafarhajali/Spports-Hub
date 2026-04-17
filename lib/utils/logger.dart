import 'package:flutter/foundation.dart';

/// Minimal logger — zero dependencies.
///
/// In release builds (`flutter run --release` / `flutter build`), `kDebugMode`
/// is false so nothing is printed — prevents tokens & PII leaking into
/// device logs. Swap to the `logger` package later if you want levels + colors.
class AppLogger {
  static void debug(String msg, {Map<String, dynamic>? meta}) {
    if (!kDebugMode) return;
    // ignore: avoid_print
    print('[DEBUG] $msg${meta != null ? ' ${meta.toString()}' : ''}');
  }

  static void info(String msg, {Map<String, dynamic>? meta}) {
    if (!kDebugMode) return;
    // ignore: avoid_print
    print('[INFO] $msg${meta != null ? ' ${meta.toString()}' : ''}');
  }

  static void warn(String msg, {Map<String, dynamic>? meta}) {
    if (!kDebugMode) return;
    // ignore: avoid_print
    print('[WARN] $msg${meta != null ? ' ${meta.toString()}' : ''}');
  }

  /// Errors always log, even in release — but be careful what you pass in.
  static void error(String msg, {Object? error, StackTrace? stack}) {
    // ignore: avoid_print
    print('[ERROR] $msg${error != null ? ': $error' : ''}');
    if (kDebugMode && stack != null) {
      // ignore: avoid_print
      print(stack);
    }
  }
}
