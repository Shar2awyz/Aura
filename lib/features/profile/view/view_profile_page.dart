import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../comments/view/comments_sheet.dart';
import '../../home/models/post_model.dart';
import '../../home/models/profile_model.dart';
import '../../home/widgets/post_card.dart';
import '../../messages/models/chat_model.dart';
import '../../messages/repo/messages_repo.dart';
import '../../messages/view/chat_detail_page.dart';
import '../viewmodel/view_profile_cubit.dart';
import '../viewmodel/view_profile_state.dart';
import 'profile_posts_feed_page.dart';
import 'widgets/profile_grid_item.dart';
import 'widgets/profile_stats_row.dart';
import 'followers_page.dart';
import 'following_page.dart';

class ViewProfilePage extends StatelessWidget {
  final String userId;

  const ViewProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ViewProfileCubit()..loadProfile(userId),
      child: const _ViewProfileBody(),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _ViewProfileBody extends StatelessWidget {
  const _ViewProfileBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ViewProfileCubit, ViewProfileState>(
      builder: (context, state) {
        if (state is ViewProfileLoading || state is ViewProfileInitial) {
          return const _LoadingView();
        }
        if (state is ViewProfileFailure) {
          return _ErrorView(
            error: state.error,
            onRetry: () {
              // userId not available here; pop and re-navigate if needed
            },
          );
        }
        if (state is ViewProfileSuccess) {
          return _SuccessView(state: state);
        }
        return const _LoadingView();
      },
    );
  }
}

// ── Success ───────────────────────────────────────────────────────────────────

class _SuccessView extends StatefulWidget {
  final ViewProfileSuccess state;

  const _SuccessView({required this.state});

  @override
  State<_SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<_SuccessView> {
  bool _openingChat = false;

  Future<void> _openChat() async {
    if (_openingChat) return;
    setState(() => _openingChat = true);
    try {
      final repo = MessagesRepo();
      final chatId = await repo.createOrGetDirectChat(widget.state.profile.id);
      final chats = await repo.fetchChats();
      final chat = chats.firstWhere(
        (c) => c.id == chatId,
        orElse: () => ChatModel(
          id: chatId,
          isGroup: false,
          updatedAt: DateTime.now(),
          otherMembers: [widget.state.profile],
        ),
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatDetailPage(chat: chat)),
      );
    } catch (e, stack) {
      debugPrint('Error opening chat: $e\n$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open chat: $e'),
          backgroundColor: AppColors.darkSurface,
        ),
      );
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  void _navigateToFeed(BuildContext context, List<PostModel> postsList, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ViewProfileCubit>(),
          child: ProfilePostsFeedPage(
            posts: postsList,
            initialIndex: index,
            postBuilder: (feedCtx, post) {
              return BlocBuilder<ViewProfileCubit, ViewProfileState>(
                builder: (context, state) {
                  final latestPost = (state is ViewProfileSuccess)
                      ? state.posts.firstWhere((p) => p.id == post.id, orElse: () => post)
                      : post;
                  return PostCard(
                    post: latestPost,
                    onLike: () => context.read<ViewProfileCubit>().toggleLike(latestPost.id),
                    onComment: () => CommentsSheet.show(context, latestPost),
                    onSave: () => context.read<ViewProfileCubit>().toggleSave(latestPost.id),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: CustomScrollView(
        slivers: [
          // ── App bar ───────────────────────────────────────────────────────
          _ViewProfileAppBar(username: state.profile.username),

          // ── Avatar ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _AvatarSection(profile: state.profile),
          ),

          // ── Name + username ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _NameSection(profile: state.profile),
          ),

          // ── Stats ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: ProfileStatsRow(
                followersCount: state.followersCount,
                followingCount: state.profile.followingCount,
                auraScore: state.profile.auraScore,
                onFollowersTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => FollowersPage(userId: state.profile.id)),
                ),
                onFollowingTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => FollowingPage(userId: state.profile.id)),
                ),
              ),
            ),
          ),

          // ── Action buttons ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ActionButtons(
              isFollowing: state.isFollowing,
              isRequested: state.isRequested,
              isMessageLoading: _openingChat,
              onFollow: () => context
                  .read<ViewProfileCubit>()
                  .toggleFollow(state.profile.id),
              onMessage: _openChat,
            ),
          ),

          // ── Divider ───────────────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Divider(color: AppColors.darkBorder, height: 1),
            ),
          ),

          // ── Posts grid ────────────────────────────────────────────────────
          if (state.profile.isPrivate && !state.isFollowing)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _PrivateAccountPlaceholder(),
            )
          else if (state.posts.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyPosts(),
            )
          else
            _StaggeredPostsSliver(
              posts: state.posts,
              onPostTap: (index) => _navigateToFeed(context, state.posts, index),
            ),
        ],
      ),
    );
  }
}

// ── App bar ───────────────────────────────────────────────────────────────────

class _ViewProfileAppBar extends StatelessWidget {
  final String username;

  const _ViewProfileAppBar({required this.username});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: AppColors.darkBackground,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.darkBorder, width: 0.5),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [AppColors.logoGradientStart, AppColors.logoGradientEnd],
        ).createShader(bounds),
        child: const Text(
          'Aura',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.more_horiz_rounded,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () {},
        ),
      ],
    );
  }
}

// ── Avatar section ────────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  final ProfileModel profile;

  const _AvatarSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final avatarSize = (w * 0.26).clamp(80.0, 120.0);
    const ringThickness = 3.0;
    const ringGap = 2.5;
    final outerSize = avatarSize + (ringThickness + ringGap) * 2;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: w * 0.06),
      child: Column(
        children: [
          // Gradient ring + avatar
          SizedBox(
            width: outerSize,
            height: outerSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
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
                    padding: const EdgeInsets.all(ringThickness + ringGap),
                    child: _AvatarCircle(
                      avatarUrl: profile.avatarUrl,
                      displayName: profile.displayName,
                      size: avatarSize,
                    ),
                  ),
                ),
                if (profile.isVerified)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: _VerifiedBadge(size: (avatarSize * 0.26).clamp(18, 28)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
          errorBuilder: (_, _, _) => _placeholder,
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

class _VerifiedBadge extends StatelessWidget {
  final double size;

  const _VerifiedBadge({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
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
          child: Icon(Icons.check_rounded, color: Colors.white, size: size * 0.52),
        ),
      ),
    );
  }
}

// ── Name + username section ───────────────────────────────────────────────────

class _NameSection extends StatelessWidget {
  final ProfileModel profile;

  const _NameSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profile.displayName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: (w * 0.058).clamp(18.0, 26.0),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (profile.isVerified) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '@${profile.username}',
            style: TextStyle(
              color: AppColors.textSubtleOnDark,
              fontSize: (w * 0.035).clamp(12.0, 15.0),
            ),
          ),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              profile.bio!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Follow + Message buttons ──────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final bool isFollowing;
  final bool isRequested;
  final bool isMessageLoading;
  final VoidCallback onFollow;
  final VoidCallback onMessage;

  const _ActionButtons({
    required this.isFollowing,
    required this.isRequested,
    required this.onFollow,
    required this.onMessage,
    this.isMessageLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final btnHeight = (w * 0.112).clamp(40.0, 52.0);
    
    final bool hasActionStyle = isFollowing || isRequested;
    final String buttonText = isFollowing
        ? 'Following'
        : (isRequested ? 'Requested' : 'Follow');

    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.06, 18, w * 0.06, 0),
      child: Row(
        children: [
          // Follow / Following / Requested button
          Expanded(
            child: GestureDetector(
              onTap: onFollow,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: btnHeight,
                decoration: BoxDecoration(
                  gradient: hasActionStyle
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFFA78BFA), Color(0xFF7C5FC8)],
                        ),
                  color: hasActionStyle ? AppColors.darkSurface : null,
                  borderRadius: BorderRadius.circular(12),
                  border: hasActionStyle
                      ? Border.all(color: AppColors.darkBorder, width: 0.8)
                      : null,
                ),
                child: Center(
                  child: Text(
                    buttonText,
                    style: TextStyle(
                      color: hasActionStyle ? AppColors.textOnDark : Colors.white,
                      fontSize: (w * 0.038).clamp(13.0, 16.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Message button
          Expanded(
            child: GestureDetector(
              onTap: isMessageLoading ? null : onMessage,
              child: Container(
                height: btnHeight,
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder, width: 0.8),
                ),
                child: Center(
                  child: isMessageLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Message',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: (w * 0.038).clamp(13.0, 16.0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Staggered posts grid ──────────────────────────────────────────────────────
// Pattern (alternating per group of 3):
//   Even groups → Large LEFT  + 2 small RIGHT
//   Odd groups  → 2 small LEFT + Large RIGHT

class _StaggeredPostsSliver extends StatelessWidget {
  final List<PostModel> posts;
  final void Function(int index)? onPostTap;

  const _StaggeredPostsSliver({required this.posts, this.onPostTap});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    const gap = 2.0;
    final halfW = (w - gap) / 2;
    final tileH = halfW; // small tile = square
    final largeH = tileH * 2 + gap;

    final rowCount = (posts.length / 3).ceil();
    final rows = <Widget>[];

    for (var g = 0; g < rowCount; g++) {
      final base = g * 3;
      final largeOnLeft = g.isEven;

      // Collect up to 3 posts for this group
      final p0 = base < posts.length ? posts[base] : null;
      final p1 = base + 1 < posts.length ? posts[base + 1] : null;
      final p2 = base + 2 < posts.length ? posts[base + 2] : null;

      if (p0 == null) break;

      if (g > 0) rows.add(const SizedBox(height: gap));

      rows.add(
        SizedBox(
          height: largeH,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: largeOnLeft
                ? [
                    // Large post (left)
                    SizedBox(
                      width: halfW,
                      height: largeH,
                      child: ProfileGridItem(post: p0, onTap: () => onPostTap?.call(base)),
                    ),
                    const SizedBox(width: gap),
                    // Two small posts (right)
                    SizedBox(
                      width: halfW,
                      child: Column(
                        children: [
                          if (p1 != null)
                            SizedBox(
                              height: tileH,
                              child: ProfileGridItem(post: p1, onTap: () => onPostTap?.call(base + 1)),
                            )
                          else
                            SizedBox(height: tileH),
                          const SizedBox(height: gap),
                          if (p2 != null)
                            SizedBox(
                              height: tileH,
                              child: ProfileGridItem(post: p2, onTap: () => onPostTap?.call(base + 2)),
                            )
                          else
                            SizedBox(height: tileH),
                        ],
                      ),
                    ),
                  ]
                : [
                    // Two small posts (left)
                    SizedBox(
                      width: halfW,
                      child: Column(
                        children: [
                          SizedBox(
                            height: tileH,
                            child: ProfileGridItem(post: p0, onTap: () => onPostTap?.call(base)),
                          ),
                          const SizedBox(height: gap),
                          if (p1 != null)
                            SizedBox(
                              height: tileH,
                              child: ProfileGridItem(post: p1, onTap: () => onPostTap?.call(base + 1)),
                            )
                          else
                            SizedBox(height: tileH),
                        ],
                      ),
                    ),
                    const SizedBox(width: gap),
                    // Large post (right)
                    if (p2 != null)
                      SizedBox(
                        width: halfW,
                        height: largeH,
                        child: ProfileGridItem(post: p2, onTap: () => onPostTap?.call(base + 2)),
                      )
                    else
                      SizedBox(width: halfW, height: largeH),
                  ],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        ),
      ),
    );
  }
}

// ── Empty posts ───────────────────────────────────────────────────────────────

class _EmptyPosts extends StatelessWidget {
  const _EmptyPosts();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 52,
            color: AppColors.textSubtleOnDark.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 14),
          const Text(
            'No posts yet',
            style: TextStyle(
              color: AppColors.textSubtleOnDark,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

// ── Private Account Placeholder ────────────────────────────────────────────────

class _PrivateAccountPlaceholder extends StatelessWidget {
  const _PrivateAccountPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.darkBorder, width: 0.5),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'This account is private',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Follow this account to see their photos and videos.',
            style: TextStyle(
              color: AppColors.textSubtleOnDark,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.primary,
                size: 52,
              ),
              const SizedBox(height: 14),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSubtleOnDark,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Go back',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
