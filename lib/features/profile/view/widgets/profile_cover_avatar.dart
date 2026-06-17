import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

// Shared constants so SizedBox height and avatar placement stay in sync.
const double _kRingThickness = 3.0;
const double _kRingGap = 2.0; // gap between ring paint and avatar edge

class ProfileCoverAvatar extends StatelessWidget {
  final String? coverUrl;
  final String? avatarUrl;
  final String displayName;
  final bool isVerified;

  const ProfileCoverAvatar({
    super.key,
    this.coverUrl,
    this.avatarUrl,
    required this.displayName,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final coverHeight = (w * 0.54).roundToDouble();
    final avatarSize = (w * 0.23).roundToDouble();
    final outerSize = avatarSize + (_kRingThickness + _kRingGap) * 2;
    // SizedBox must be tall enough to contain the lower half of the avatar ring.
    final totalHeight = coverHeight + outerSize / 2 + 16;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Cover ────────────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: coverHeight,
            child: _CoverImage(url: coverUrl),
          ),

          // ── Avatar ring, centered horizontally ────────────────────────────
          Positioned(
            // Top of the ring = cover bottom – half of ring height
            top: coverHeight - outerSize / 2,
            left: 0,
            right: 0,
            child: Center(
              child: _AvatarWithRing(
                avatarUrl: avatarUrl,
                displayName: displayName,
                avatarSize: avatarSize,
                outerSize: outerSize,
                isVerified: isVerified,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cover image ───────────────────────────────────────────────────────────────

class _CoverImage extends StatelessWidget {
  final String? url;

  const _CoverImage({this.url});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return Image.network(
        url!,
        fit: BoxFit.cover,
        width: double.infinity,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _fallback,
        errorBuilder: (context, error, stack) => _fallback,
      );
    }
    return _fallback;
  }

  Widget get _fallback => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1C1A2E),
              Color(0xFF2A1A4E),
              Color(0xFF1A2E3C),
            ],
          ),
        ),
      );
}

// ── Avatar with gradient ring ─────────────────────────────────────────────────

class _AvatarWithRing extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;
  final double avatarSize;
  final double outerSize;
  final bool isVerified;

  const _AvatarWithRing({
    required this.avatarUrl,
    required this.displayName,
    required this.avatarSize,
    required this.outerSize,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    final badgeSize = (avatarSize * 0.28).clamp(18.0, 28.0);
    final innerPadding = _kRingThickness + _kRingGap;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Gradient ring
        Container(
          width: outerSize,
          height: outerSize,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Color(0xFF00D4FF),
                Color(0xFFA78BFA),
                Color(0xFFFF6B9D),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(innerPadding),
            child: _AvatarCircle(
              avatarUrl: avatarUrl,
              displayName: displayName,
              size: avatarSize,
            ),
          ),
        ),

        // Verification badge — anchored to bottom-right of the ring circle
        if (isVerified)
          Positioned(
            bottom: 1,
            right: 1,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.darkBackground,
                shape: BoxShape.circle,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1D9BF0),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: badgeSize * 0.52,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Avatar circle ─────────────────────────────────────────────────────────────

class _AvatarCircle extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;
  final double size;

  const _AvatarCircle({
    required this.avatarUrl,
    required this.displayName,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : _placeholder,
          errorBuilder: (context, error, stack) => _placeholder,
        ),
      );
    }
    return _placeholder;
  }

  Widget get _placeholder => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.darkSurface,
        ),
        child: Center(
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.38,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
}
