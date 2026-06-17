import 'package:supabase_flutter/supabase_flutter.dart';

class Authrepo {
  Future<void> signupwithemailandpassword(
    String email,
    String password, {
    Map<String, dynamic>? userData,
  }) async {
    await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: userData,
    );
  }

  Future<void> loginusingemailandpassword(String email, String password) async {
    await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> resetPassword(String email) async {
    await Supabase.instance.client.auth.resetPasswordForEmail(email);
  }

  Future<void> updatePassword(String newPassword) async {
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
