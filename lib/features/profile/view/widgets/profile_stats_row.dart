import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileStatsRow extends StatelessWidget {
  final int followersCount;
  final int followingCount;
  final int auraScore;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;

  const ProfileStatsRow({
    super.key,
    required this.followersCount,
    required this.followingCount,
    required this.auraScore,
    this.onFollowersTap,
    this.onFollowingTap,
  });


  static String _format(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: w * 0.06),
      padding: EdgeInsets.symmetric(vertical: w * 0.04),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onFollowersTap,
              child: _StatItem(
                value: _format(followersCount),
                label: 'FOLLOWERS',
                valueColor: Colors.white,
              ),
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: GestureDetector(
              onTap: onFollowingTap,
              child: _StatItem(
                value: _format(followingCount),
                label: 'FOLLOWING',
                valueColor: AppColors.primary,
              ),
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _StatItem(
              value: _format(auraScore),
              label: 'AURA SCORE',
              valueColor: const Color(0xFFFF9F43),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single stat column ────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _StatItem({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: (w * 0.048).clamp(16.0, 22.0),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSubtleOnDark,
            fontSize: (w * 0.023).clamp(8.0, 11.0),
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 32,
        color: AppColors.darkBorder,
      );
}
