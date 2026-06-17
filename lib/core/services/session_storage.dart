import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists a SHA-256 hash of the Supabase access token in SharedPreferences.
///
/// The raw token is never written to disk — only its hash (+ app salt).
/// Supabase's own secure storage handles the actual session; this class adds
/// a lightweight local proof that the user authenticated on this device.
class SessionStorage {
  // Obfuscated key so the purpose is not obvious in plain pref dumps.
  static const _prefKey = '_a_sk_v1';
  // Salt mixed into every hash so the stored value is app-specific.
  static const _salt = 'aura.soc.2026';

  SessionStorage._();

  static String _hash(String token) {
    final bytes = utf8.encode('$token:$_salt');
    return sha256.convert(bytes).toString();
  }

  /// Hashes [accessToken] and writes the result to SharedPreferences.
  static Future<void> save(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _hash(accessToken));
  }

  /// Returns true if the stored hash matches a fresh hash of [accessToken].
  static Future<bool> verify(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKey);
    return stored != null && stored == _hash(accessToken);
  }

  /// Removes the stored hash (call on sign-out or session expiry).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
}
