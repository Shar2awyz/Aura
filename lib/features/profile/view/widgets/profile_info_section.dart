import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileInfoSection extends StatelessWidget {
  final String displayName;
  final String username;
  final String? bio;

  const ProfileInfoSection({
    super.key,
    required this.displayName,
    required this.username,
    this.bio,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final nameFontSize = w * 0.058;
    final usernameFontSize = w * 0.036;
    final bioFontSize = w * 0.034;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.06),
      child: Column(
        children: [
          Text(
            displayName,
            style: TextStyle(
              color: Colors.white,
              fontSize: nameFontSize.clamp(18.0, 26.0),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            '@$username',
            style: TextStyle(
              color: AppColors.textSubtleOnDark,
              fontSize: usernameFontSize.clamp(12.0, 16.0),
              fontWeight: FontWeight.w400,
            ),
          ),
          if (bio != null && bio!.isNotEmpty) ...[
            SizedBox(height: w * 0.025),
            Text(
              bio!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textOnDark,
                fontSize: bioFontSize.clamp(12.0, 14.0),
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
