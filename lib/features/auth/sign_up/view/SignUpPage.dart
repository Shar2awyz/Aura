import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled/features/auth/log_in/view/LoginPage.dart';
import '../../../../core/components/auth_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodel/SignUpCubit.dart';
import '../viewmodel/SignUpState.dart';

class Signuppage extends StatefulWidget {
  const Signuppage({super.key});

  @override
  State<Signuppage> createState() => _SignuppageState();
}

class _SignuppageState extends State<Signuppage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordObscured = true;
  bool _isConfirmObscured = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => Signupcubit(),
      child: _SignUpBody(
        fullNameController: _fullNameController,
        emailController: _emailController,
        usernameController: _usernameController,
        passwordController: _passwordController,
        confirmPasswordController: _confirmPasswordController,
        isPasswordObscured: _isPasswordObscured,
        isConfirmObscured: _isConfirmObscured,
        onTogglePassword: () =>
            setState(() => _isPasswordObscured = !_isPasswordObscured),
        onToggleConfirm: () =>
            setState(() => _isConfirmObscured = !_isConfirmObscured),
      ),
    );
  }
}

class _SignUpBody extends StatelessWidget {
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isPasswordObscured;
  final bool isConfirmObscured;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;

  const _SignUpBody({
    required this.fullNameController,
    required this.emailController,
    required this.usernameController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isPasswordObscured,
    required this.isConfirmObscured,
    required this.onTogglePassword,
    required this.onToggleConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final hPad = size.width * 0.06;

    return BlocConsumer<Signupcubit, Signupstate>(
      listener: (context, state) {
        if (state is SignUpFailure) {
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
        else
          if(state is SignUpSuccess){

            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>LoginPage()), (route) => false);
          }
      },
      builder: (context, state) {
        final isLoading = state is SignUpLoading;

        return Scaffold(
          backgroundColor: AppColors.darkBackground,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: size.height * 0.06),

                  // Glowing sparkle icon
                  Container(
                    width: size.width * 0.18,
                    height: size.width * 0.18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.15),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: AppColors.primary,
                      size: size.width * 0.08,
                    ),
                  ),

                  SizedBox(height: size.height * 0.015),

                  // Logo
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        AppColors.logoGradientStart,
                        AppColors.logoGradientEnd,
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'Aura',
                      style: TextStyle(
                        fontSize: size.width < 360 ? 38 : 46,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.006),

                  Text(
                    'Elevate your digital presence.',
                    style: TextStyle(
                      color: AppColors.textOnDark,
                      fontSize: size.width < 360 ? 13 : 14,
                    ),
                  ),

                  SizedBox(height: size.height * 0.04),

                  // Left-aligned heading
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size.width < 360 ? 22 : 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Join the community of innovators.',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: size.width < 360 ? 13 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: size.height * 0.032),

                  // Full Name
                  AuthTextField(
                    controller: fullNameController,
                    hint: 'Full Name',
                    prefixIcon: Icons.person_outline_rounded,
                    keyboardType: TextInputType.name,
                  ),

                  SizedBox(height: size.height * 0.018),

                  // Email
                  AuthTextField(
                    controller: emailController,
                    hint: 'Email Address',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  SizedBox(height: size.height * 0.018),

                  // Username
                  AuthTextField(
                    controller: usernameController,
                    hint: 'Username',
                    prefixIcon: Icons.alternate_email_rounded,
                  ),

                  SizedBox(height: size.height * 0.018),

                  // Password
                  AuthTextField(
                    controller: passwordController,
                    hint: 'Password',
                    prefixIcon: Icons.lock_outline_rounded,
                    isObscured: isPasswordObscured,
                    onToggleObscure: onTogglePassword,
                  ),

                  SizedBox(height: size.height * 0.018),

                  // Confirm Password
                  AuthTextField(
                    controller: confirmPasswordController,
                    hint: 'Confirm Password',
                    prefixIcon: Icons.lock_outline_rounded,
                    isObscured: isConfirmObscured,
                    onToggleObscure: onToggleConfirm,
                  ),

                  SizedBox(height: size.height * 0.04),

                  // Create Aura button
                  _CreateButton(
                    isLoading: isLoading,
                    width: size.width - hPad * 2,
                    height: size.height * 0.065,
                    onPressed: () {
                      if (!isLoading) {
                        context.read<Signupcubit>().signup(
                              fullName: fullNameController.text,
                              email: emailController.text,
                              username: usernameController.text,
                              password: passwordController.text,
                              confirmPassword: confirmPasswordController.text,
                            );
                      }
                    },
                  ),

                  SizedBox(height: size.height * 0.035),

                  // OR SIGN UP WITH divider
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: AppColors.darkBorder, thickness: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR SIGN UP WITH',
                          style: TextStyle(
                            color: AppColors.textSubtleOnDark,
                            fontSize: size.width < 360 ? 9 : 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: AppColors.darkBorder, thickness: 1),
                      ),
                    ],
                  ),

                  SizedBox(height: size.height * 0.025),

                  // Social buttons
                  Row(
                    children: [
                      Expanded(
                        child: _SocialButton(
                          height: size.height * 0.065,
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.textOnDark,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SocialButton(
                          height: size.height * 0.065,
                          child: Text(
                            'iOS',
                            style: TextStyle(
                              color: AppColors.textOnDark,
                              fontSize: size.width < 360 ? 13 : 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: size.height * 0.035),

                  // Sign In link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>LoginPage()), (route) => false);

                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: size.height * 0.04),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CreateButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final double width;
  final double height;

  const _CreateButton({
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
              colors: [Color(0xFFC4B5FD), Color(0xFFE879F9)],
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
                    'Create Account',
                    style: TextStyle(
                      color: Color(0xFF3B0764),
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

class _SocialButton extends StatelessWidget {
  final Widget child;
  final double height;

  const _SocialButton({required this.child, required this.height});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: () {

        },
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.darkBorder, width: 1),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
