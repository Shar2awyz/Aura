import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/components/auth_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodel/ForgotPasswordCubit.dart';
import '../viewmodel/ForgotPasswordState.dart';
import 'ResetPasswordPage.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ForgotPasswordCubit(),
      child: _ForgotPasswordBody(emailController: _emailController),
    );
  }
}

class _ForgotPasswordBody extends StatelessWidget {
  final TextEditingController emailController;

  const _ForgotPasswordBody({required this.emailController});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final hPad = size.width * 0.06;

    return BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
      listener: (context, state) {
        if (state is ForgotPasswordFailure) {
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
        if (state is ForgotPasswordSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Reset link sent! Check your inbox, then set your new password below.'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is ForgotPasswordLoading;

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

                  // Title
                  Text(
                    'Reset Password',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size.width < 360 ? 24 : 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: size.height * 0.01),

                  // Subtitle
                  Text(
                    'Enter your email to receive a\nrecovery link.',
                    style: TextStyle(
                      color: AppColors.textOnDark,
                      fontSize: size.width < 360 ? 13 : 14,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: size.height * 0.045),

                  // Email field
                  AuthTextField(
                    controller: emailController,
                    label: 'Email Address',
                    hint: 'hello@aura.design',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  SizedBox(height: size.height * 0.04),

                  // Send Reset Link button
                  _SendButton(
                    isLoading: isLoading,
                    width: size.width - hPad * 2,
                    height: size.height * 0.065,
                    onPressed: () {
                      if (!isLoading) {
                        context
                            .read<ForgotPasswordCubit>()
                            .sendResetLink(emailController.text.trim());
                      }
                    },
                  ),

                  // Spacer works correctly here — SafeArea > Padding > Column
                  // gives the Column a finite height, so Spacer can expand.
                  const Spacer(),

                  // Remembered it? Log in
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
                          onTap: () => Navigator.pop(context),
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

class _SendButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final double width;
  final double height;

  const _SendButton({
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
                    'Send Reset Link',
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
