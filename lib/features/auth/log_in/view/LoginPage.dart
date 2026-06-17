import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled/features/auth/forgot_password/view/ForgotPasswordPage.dart';
import 'package:untitled/features/auth/sign_up/view/SignUpPage.dart';
import 'package:untitled/features/shell/view/shell_page.dart';
import '../../../../core/components/auth_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodel/LoginCubit.dart';
import '../viewmodel/LoginState.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginCubit(),
      child: _LoginBody(
        emailController: _emailController,
        passwordController: _passwordController,
        isPasswordObscured: _isPasswordObscured,
        onTogglePassword: () =>
            setState(() => _isPasswordObscured = !_isPasswordObscured),
      ),
    );
  }
}

class _LoginBody extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isPasswordObscured;
  final VoidCallback onTogglePassword;

  const _LoginBody({
    required this.emailController,
    required this.passwordController,
    required this.isPasswordObscured,
    required this.onTogglePassword,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final hPad = size.width * 0.06;

    return BlocConsumer<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ShellPage()),
            (_) => false,
          );
        }
        if (state is LoginFailure) {
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
      },
      builder: (context, state) {
        final isLoading = state is LoginLoading;

        return Scaffold(
          backgroundColor: AppColors.darkBackground,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: size.height * 0.08),

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
                        fontSize: size.width < 360 ? 42 : 52,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.012),

                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size.width < 360 ? 22 : 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: size.height * 0.008),

                  Text(
                    'Sign in to your luminous journey.',
                    style: TextStyle(
                      color: AppColors.textSubtleOnDark,
                      fontSize: size.width < 360 ? 13 : 14,
                    ),
                  ),

                  SizedBox(height: size.height * 0.05),

                  // Email field
                  AuthTextField(
                    controller: emailController,
                    label: 'EMAIL ADDRESS',
                    hint: 'name@domain.com',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  SizedBox(height: size.height * 0.022),

                  // Password field with Forgot Password trailing
                  AuthTextField(
                    controller: passwordController,
                    label: 'PASSWORD',
                    labelTrailing: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPage(),
                        ),
                      ),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outline_rounded,
                    isObscured: isPasswordObscured,
                    onToggleObscure: onTogglePassword,
                  ),

                  SizedBox(height: size.height * 0.04),

                  // Sign In button
                  _SignInButton(
                    isLoading: isLoading,
                    width: size.width - hPad * 2,
                    height: size.height * 0.065,
                    onPressed: () {
                      if (!isLoading) {
                        context.read<LoginCubit>().login(
                              emailController.text.trim(),
                              passwordController.text.trim(),
                            );
                      }
                    },
                  ),

                  SizedBox(height: size.height * 0.035),

                  // OR CONTINUE WITH divider
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: AppColors.darkBorder, thickness: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR CONTINUE WITH',
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

                  // Sign Up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>Signuppage()));


                        },
                        child: const Text(
                          'Sign Up',
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

class _SignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final double width;
  final double height;

  const _SignInButton({
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
                    'Sign In',
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

class _SocialButton extends StatelessWidget {
  final Widget child;
  final double height;

  const _SocialButton({required this.child, required this.height});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkBorder, width: 1),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
