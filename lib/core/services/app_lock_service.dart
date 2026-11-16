import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

final appLockServiceProvider = Provider<AppLockService>((ref) {
  return AppLockService(
    const FlutterSecureStorage(),
    LocalAuthentication(),
  );
});

final isAppLockedProvider = StateProvider<bool>((ref) => false);

class AppLockService {
  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  static const _pinKey = 'user_app_pin_hash';
  static const _saltKey = 'user_app_pin_salt';
  static const _biometricKey = 'user_biometric_enabled';
  static const _lastPausedKey = 'app_last_paused_timestamp';

  AppLockService(this._storage, this._localAuth);

  Future<bool> isPinSet() async {
    final hash = await _storage.read(key: _pinKey);
    return hash != null && hash.isNotEmpty;
  }

  Future<void> savePin(String pin) async {
    final salt = DateTime.now().microsecondsSinceEpoch.toString();
    final bytes = utf8.encode(pin + salt);
    final hash = sha256.convert(bytes).toString();
    await _storage.write(key: _saltKey, value: salt);
    await _storage.write(key: _pinKey, value: hash);
  }

  Future<bool> verifyPin(String pin) async {
    final savedHash = await _storage.read(key: _pinKey);
    final salt = await _storage.read(key: _saltKey);
    if (savedHash == null || salt == null) return false;

    final bytes = utf8.encode(pin + salt);
    final inputHash = sha256.convert(bytes).toString();
    return inputHash == savedHash;
  }

  Future<void> removePin() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _saltKey);
    await _storage.delete(key: _biometricKey);
  }

  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason:
            'Pindai sidik jari atau wajah untuk membuka Personal OS',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> recordAppPaused() async {
    await _storage.write(
      key: _lastPausedKey,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  Future<bool> shouldLockOnResume(int timeoutMinutes) async {
    final lastPausedStr = await _storage.read(key: _lastPausedKey);
    if (lastPausedStr == null) return false;

    final lastPausedMs = int.tryParse(lastPausedStr);
    if (lastPausedMs == null) return false;

    final diffMs = DateTime.now().millisecondsSinceEpoch - lastPausedMs;
    final diffMinutes = diffMs / (1000 * 60);

    return diffMinutes >= timeoutMinutes;
  }
}
