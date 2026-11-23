import 'dart:async';

import 'package:flutter/services.dart';

enum AuthResult { granted, denied, unavailable }

/// Dart side of the `sensitive_screen` channel. The native halves are
/// ios/SensitiveScreen.swift and android/SensitiveScreen.kt.
class SensitiveScreen {
  SensitiveScreen() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'screenshot') _screenshots.add(null);
    });
  }

  static const _channel = MethodChannel('sensitive_screen');

  final _screenshots = StreamController<void>.broadcast();

  Stream<void> get screenshots => _screenshots.stream;

  Future<AuthResult> authenticate(String reason) async {
    try {
      final ok = await _channel.invokeMethod<bool>('authenticate', reason);
      return ok == true ? AuthResult.granted : AuthResult.denied;
    } on PlatformException catch (e) {
      return e.code == 'unavailable' ? AuthResult.unavailable : AuthResult.denied;
    } on MissingPluginException {
      return AuthResult.unavailable;
    }
  }

  /// Screenshots and recordings come out black.
  Future<bool> setShield(bool enabled) => _set('setShield', enabled);

  /// Blurs the app in the app switcher. On Android it needs 13+, and the
  /// shield already does it.
  Future<bool> setCover(bool enabled) => _set('setCover', enabled);

  Future<bool> _set(String method, bool enabled) async {
    try {
      return await _channel.invokeMethod<bool>(method, enabled) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
    _screenshots.close();
  }
}
