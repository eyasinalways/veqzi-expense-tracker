import 'package:shared_preferences/shared_preferences.dart';

class AuthHelper {
  static const String _keyAppLockEnabled = 'isAppLockEnabled';
  static const String _keyAppPin = 'appPin';
  static const String _keyAutoLockDelay = 'autoLockDelay';
  static bool isExternalIntentInProgress = false;

  // App Lock Enable/Disable
  static Future<bool> isAppLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAppLockEnabled) ?? false;
  }

  static Future<void> setAppLockEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAppLockEnabled, value);
  }

  // App PIN
  static Future<String?> getAppPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAppPin);
  }

  static Future<void> setAppPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppPin, pin);
  }

  // Auto Lock Delay (in seconds). 0 = Immediately
  static Future<int> getAutoLockDelay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyAutoLockDelay) ?? 0;
  }

  static Future<void> setAutoLockDelay(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAutoLockDelay, seconds);
  }
}
