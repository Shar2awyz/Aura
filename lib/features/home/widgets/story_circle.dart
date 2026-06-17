import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class StoryCircle extends StatelessWidget {
  final String? imageUrl;
  final bool isActive;
  final double size;

  const StoryCircle({
    super.key,
    this.imageUrl,
    this.isActive = true,
    this.size = 62,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 5,
      height: size + 5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isActive
            ? const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isActive ? null : Colors.white.withValues(alpha: 0.15),
      ),
      padding: const EdgeInsets.all(2.5),
      child: CircleAvatar(
        backgroundColor: AppColors.darkBackground,
        backgroundImage:
            imageUrl != null ? NetworkImage(imageUrl!) : null,
        child: imageUrl == null
            ? Icon(Icons.person, color: AppColors.primary, size: size * 0.4)
            : null,
      ),
    );
  }
}
