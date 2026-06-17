import 'package:hive_flutter/hive_flutter.dart';

class SavedAccountsStorage {
  static const String boxName = 'saved_accounts';

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static Box get _box => Hive.box(boxName);

  /// Saves or updates a user's account details.
  static Future<void> saveAccount({
    required String userId,
    required String email,
    required String password,
    required String username,
    required String avatarUrl,
  }) async {
    await _box.put(userId, {
      'id': userId,
      'email': email,
      'password': password,
      'username': username,
      'avatar_url': avatarUrl,
      'last_used': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Retrieves all saved accounts, sorted by the last used time (most recent first).
  static List<Map<String, dynamic>> getAccounts() {
    final list = _box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    list.sort((a, b) => (b['last_used'] as int? ?? 0).compareTo(a['last_used'] as int? ?? 0));
    return list;
  }

  /// Removes an account from the saved list.
  static Future<void> removeAccount(String userId) async {
    await _box.delete(userId);
  }

  /// Clears all saved accounts.
  static Future<void> clear() async {
    await _box.clear();
  }
}
