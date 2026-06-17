import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final Widget? labelTrailing;
  final String hint;
  final IconData prefixIcon;
  final bool isObscured;
  final VoidCallback? onToggleObscure;
  final TextInputType keyboardType;

  const AuthTextField({
    super.key,
    required this.controller,
    this.label,
    required this.hint,
    required this.prefixIcon,
    this.labelTrailing,
    this.isObscured = false,
    this.onToggleObscure,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double iconSize = constraints.maxWidth < 360 ? 18.0 : 20.0;
        final double fontSize = constraints.maxWidth < 360 ? 13.0 : 14.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null || labelTrailing != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (label case final lbl?) Text(
                    lbl,
                    style: const TextStyle(
                      color: AppColors.textSubtleOnDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (labelTrailing case final trailing?) trailing,
                ],
              ),
              const SizedBox(height: 8),
            ],
            Container(
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.darkBorder, width: 1),
              ),
              child: TextField(
                controller: controller,
                obscureText: isObscured,
                keyboardType: keyboardType,
                style: TextStyle(
                  color: AppColors.textOnDark,
                  fontSize: fontSize,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: AppColors.textSubtleOnDark,
                    fontSize: fontSize,
                  ),
                  prefixIcon: Icon(
                    prefixIcon,
                    color: AppColors.textSubtleOnDark,
                    size: iconSize,
                  ),
                  suffixIcon: onToggleObscure != null
                      ? InkWell(
                          onTap: onToggleObscure,
                          borderRadius: BorderRadius.circular(35),
                          child: Icon(
                            isObscured
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSubtleOnDark,
                            size: iconSize,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
