import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/components/auth_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodel/ResetPasswordCubit.dart';
import '../viewmodel/ResetPasswordState.dart';
import '../../log_in/view/LoginPage.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ResetPasswordCubit(),
      child: _ResetPasswordBody(
        newPasswordController: _newPasswordController,
        confirmPasswordController: _confirmPasswordController,
        isNewPasswordObscured: _isNewPasswordObscured,
        isConfirmPasswordObscured: _isConfirmPasswordObscured,
        onToggleNewPassword: () =>
            setState(() => _isNewPasswordObscured = !_isNewPasswordObscured),
        onToggleConfirmPassword: () => setState(
            () => _isConfirmPasswordObscured = !_isConfirmPasswordObscured),
      ),
    );
  }
}

class _ResetPasswordBody extends StatelessWidget {
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool isNewPasswordObscured;
  final bool isConfirmPasswordObscured;
  final VoidCallback onToggleNewPassword;
  final VoidCallback onToggleConfirmPassword;

  const _ResetPasswordBody({
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.isNewPasswordObscured,
    required this.isConfirmPasswordObscured,
    required this.onToggleNewPassword,
    required this.onToggleConfirmPassword,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final hPad = size.width * 0.06;

    return BlocConsumer<ResetPasswordCubit, ResetPasswordState>(
      listener: (context, state) {
        if (state is ResetPasswordFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        if (state is ResetPasswordSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Password updated successfully! Please log in.'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          // Navigate back to login, clearing the whole stack
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is ResetPasswordLoading;

        return Scaffold(
          backgroundColor: AppColors.darkBackground,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: size.height * 0.025),

                  // Back button
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(50),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(50),
                      child: Ink(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.darkSurface,
                          border: Border.all(
                            color: AppColors.darkBorder,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: AppColors.textOnDark,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.04),

                  // Lock icon decoration
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),

                  SizedBox(height: size.height * 0.025),

                  // Title
                  Text(
                    'New Password',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size.width < 360 ? 24 : 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: size.height * 0.01),

                  // Subtitle
                  Text(
                    'Create a strong new password\nfor your account.',
                    style: TextStyle(
                      color: AppColors.textOnDark,
                      fontSize: size.width < 360 ? 13 : 14,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: size.height * 0.045),

                  // New Password field
                  AuthTextField(
                    controller: newPasswordController,
                    label: 'NEW PASSWORD',
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outline_rounded,
                    isObscured: isNewPasswordObscured,
                    onToggleObscure: onToggleNewPassword,
                  ),

                  SizedBox(height: size.height * 0.022),

                  // Confirm Password field
                  AuthTextField(
                    controller: confirmPasswordController,
                    label: 'CONFIRM PASSWORD',
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outline_rounded,
                    isObscured: isConfirmPasswordObscured,
                    onToggleObscure: onToggleConfirmPassword,
                  ),

                  SizedBox(height: size.height * 0.04),

                  // Password strength hint
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.darkBorder, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Password must be at least 6 characters long.',
                            style: TextStyle(
                              color: AppColors.textOnDark,
                              fontSize: size.width < 360 ? 11 : 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: size.height * 0.04),

                  // Update Password button
                  _UpdateButton(
                    isLoading: isLoading,
                    width: size.width - hPad * 2,
                    height: size.height * 0.065,
                    onPressed: () {
                      if (!isLoading) {
                        context.read<ResetPasswordCubit>().updatePassword(
                              newPasswordController.text.trim(),
                              confirmPasswordController.text.trim(),
                            );
                      }
                    },
                  ),

                  const Spacer(),

                  // Back to login
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Remembered it?  ',
                          style: TextStyle(
                            color: AppColors.textOnDark,
                            fontSize: 14,
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginPage()),
                            (_) => false,
                          ),
                          child: const Text(
                            'Log in',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: size.height * 0.03),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UpdateButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final double width;
  final double height;

  const _UpdateButton({
    required this.isLoading,
    required this.onPressed,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Update Password',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
