import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled/features/auth/AuthRepo.dart';
import 'ResetPasswordState.dart';

class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  ResetPasswordCubit() : super(ResetPasswordInitial());

  final Authrepo _authrepo = Authrepo();

  Future<void> updatePassword(String newPassword, String confirmPassword) async {
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      emit(ResetPasswordFailure('Please fill in all fields.'));
      return;
    }
    if (newPassword.length < 6) {
      emit(ResetPasswordFailure('Password must be at least 6 characters.'));
      return;
    }
    if (newPassword != confirmPassword) {
      emit(ResetPasswordFailure('Passwords do not match.'));
      return;
    }

    emit(ResetPasswordLoading());
    try {
      await _authrepo.updatePassword(newPassword);
      emit(ResetPasswordSuccess());
    } catch (e) {
      emit(ResetPasswordFailure(e.toString()));
    }
  }
}
