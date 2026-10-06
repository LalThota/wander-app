import 'package:flutter/foundation.dart';

/// Override at run time:
///   flutter run --dart-define=API_URL=http://192.168.1.20:8000
const _override = String.fromEnvironment('API_URL');

String get apiBase {
  if (_override.isNotEmpty) return _override;
  // The Android emulator reaches your computer at 10.0.2.2, not localhost.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000';
  }
  return 'http://localhost:8000';
}
