import 'package:shared_preferences/shared_preferences.dart';

class SettingsStorage {
  static const _darkModeKey = 'is_dark_mode';
  static const _notificationsStoppedKey = 'notifications_stopped';

  static Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to dark mode (true)
    return prefs.getBool(_darkModeKey) ?? true;
  }

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  static Future<bool> areNotificationsStopped() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsStoppedKey) ?? false;
  }

  static Future<void> setNotificationsStopped(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsStoppedKey, value);
  }
}
