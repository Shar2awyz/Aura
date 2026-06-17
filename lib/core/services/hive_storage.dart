import 'package:hive_flutter/hive_flutter.dart';
import 'saved_accounts_storage.dart';

class HiveStorage {
  static const String boxName = 'messaged_users';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);
    await SavedAccountsStorage.init();
  }

  static Box get _box => Hive.box(boxName);

  /// Saves user information to local storage if it doesn't already exist.
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final userId = user['id'] as String;
    if (!_box.containsKey(userId)) {
      await _box.put(userId, {
        'id': userId,
        'username': user['username'] ?? '',
        'full_name': user['full_name'] ?? '',
        'avatar_url': user['avatar_url'] ?? '',
      });
    }
  }

  /// Retrieves all users saved in local storage.
  static List<Map<String, dynamic>> getSavedUsers() {
    return _box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Checks if a user is already saved in local storage.
  static bool isUserSaved(String userId) {
    return _box.containsKey(userId);
  }
}
