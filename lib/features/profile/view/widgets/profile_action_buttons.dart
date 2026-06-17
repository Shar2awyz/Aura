import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileActionButtons extends StatelessWidget {
  final VoidCallback onEditProfile;
  final VoidCallback onShare;

  const ProfileActionButtons({
    super.key,
    required this.onEditProfile,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final buttonHeight = (w * 0.115).clamp(40.0, 52.0);
    final iconButtonSize = buttonHeight;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.06),
      child: Row(
        children: [
          // ── Edit Profile ───────────────────────────────────────────────────
          Expanded(
            child: SizedBox(
              height: buttonHeight,
              child: ElevatedButton.icon(
                onPressed: onEditProfile,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text(
                  'Edit Profile',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkSurface,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                      color: AppColors.darkBorder,
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(width: w * 0.03),

          // ── Share ──────────────────────────────────────────────────────────
          Container(
            width: iconButtonSize,
            height: iconButtonSize,
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorder, width: 0.5),
            ),
            child: IconButton(
              onPressed: onShare,
              icon: const Icon(
                Icons.ios_share_outlined,
                color: Colors.white,
                size: 20,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
