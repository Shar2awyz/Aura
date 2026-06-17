import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/core/services/session_storage.dart';
import 'package:untitled/core/services/saved_accounts_storage.dart';
import 'package:untitled/features/auth/AuthRepo.dart';
import 'LoginState.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(LoginInitial());

  final Authrepo _authrepo = Authrepo();

  Future<void> login(String email, String password) async {
    emit(LoginLoading());
    try {
      await _authrepo.loginusingemailandpassword(email, password);
      // Persist a hash of the access token before navigating away.
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await SessionStorage.save(session.accessToken);

        // Fetch and save user profile to local accounts list
        final user = session.user;
        try {
          final profileData = await Supabase.instance.client
              .from('profiles')
              .select()
              .eq('id', user.id)
              .maybeSingle();
          if (profileData != null) {
            await SavedAccountsStorage.saveAccount(
              userId: user.id,
              email: email,
              password: password,
              username: profileData['username'] as String? ?? 'user',
              avatarUrl: profileData['avatar_url'] as String? ?? '',
            );
          }
        } catch (_) {
          // Best-effort profile saving
        }
      }
      emit(LoginSuccess());
    } catch (e) {
      emit(LoginFailure(e.toString()));
    }
  }
}
