// lib/services/app_logger.dart
// Centralised error logging. Debug mode: prints to console with full stack.
// Release mode: ready to route to Crashlytics by adding one call here.

import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  /// Log a caught exception with context label and optional stack trace.
  /// Use for ALL non-audio async failures (SharedPreferences, JSON, etc.).
  static void error(String context, Object error, [StackTrace? stack]) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[AppLogger] ERROR in $context: $error');
      if (stack != null) print(stack.toString());
    }
    // When Firebase is added: FirebaseCrashlytics.instance.recordError(error, stack, reason: context);
  }

  /// Log a non-fatal warning.
  static void warn(String context, String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[AppLogger] WARN  in $context: $message');
    }
  }

  /// Log informational messages (e.g. migration completed).
  static void info(String context, String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[AppLogger] INFO  in $context: $message');
    }
  }
}
