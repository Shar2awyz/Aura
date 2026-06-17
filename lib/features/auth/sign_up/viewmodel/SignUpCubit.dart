import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/core/utils/auth_validators.dart';
import 'package:untitled/features/auth/sign_up/viewmodel/SignUpState.dart';
import '../../AuthRepo.dart';

class Signupcubit extends Cubit<Signupstate> {
  Signupcubit() : super(SignUpInitial());

  final Authrepo _authrepo = Authrepo();

  void signup({
    required String fullName,
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    final nameError = AuthValidators.validateFullName(fullName);
    if (nameError != null) { emit(SignUpFailure(nameError)); return; }

    final emailError = AuthValidators.validateEmail(email);
    if (emailError != null) { emit(SignUpFailure(emailError)); return; }

    final usernameError = AuthValidators.validateUsername(username);
    if (usernameError != null) { emit(SignUpFailure(usernameError)); return; }

    final passwordError = AuthValidators.validatePassword(password);
    if (passwordError != null) { emit(SignUpFailure(passwordError)); return; }

    final confirmError = AuthValidators.validateConfirmPassword(password, confirmPassword);
    if (confirmError != null) { emit(SignUpFailure(confirmError)); return; }

    emit(SignUpLoading());
    try {
      await _authrepo.signupwithemailandpassword(
        email.trim(),
        password,
        userData: {
          'full_name': fullName.trim(),
          'username': username.trim(),

        },

      );
      Supabase.instance.client.from('');
      emit(SignUpSuccess());
    } catch (e) {
      emit(SignUpFailure(e.toString()));
    }
  }
}
