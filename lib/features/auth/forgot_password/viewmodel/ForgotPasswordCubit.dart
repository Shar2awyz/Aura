import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled/core/utils/auth_validators.dart';
import 'package:untitled/features/auth/AuthRepo.dart';
import 'ForgotPasswordState.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit() : super(ForgotPasswordInitial());

  final Authrepo _authrepo = Authrepo();

  Future<void> sendResetLink(String email) async {
    final emailError = AuthValidators.validateEmail(email);
    if (emailError != null) {
      emit(ForgotPasswordFailure(emailError));
      return;
    }

    emit(ForgotPasswordLoading());
    try {
      await _authrepo.resetPassword(email.trim());
      emit(ForgotPasswordSuccess());
    } catch (e) {
      emit(ForgotPasswordFailure(e.toString()));
    }
  }
}
