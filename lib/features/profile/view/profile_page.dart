import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/home/models/post_model.dart';
import '../../../features/home/models/profile_model.dart';
import '../../comments/view/comments_sheet.dart';
import '../../home/widgets/post_card.dart';
import '../viewmodel/profile_cubit.dart';
import '../viewmodel/profile_state.dart';
import 'profile_posts_feed_page.dart';
import 'widgets/profile_action_buttons.dart';
import 'widgets/profile_cover_avatar.dart';
import 'widgets/profile_info_section.dart';
import '../edit_profile_page.dart';
import 'widgets/profile_posts_grid.dart';
import 'widgets/profile_stats_row.dart';
import 'followers_page.dart';
import 'following_page.dart';
import 'widgets/profile_tab_bar.dart';
import 'settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit()..loadProfile(),
      child: const _ProfileBody(),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _ProfileBody extends StatefulWidget {
  const _ProfileBody();

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading || state is ProfileInitial) {
          return const _LoadingView();
        }
        if (state is ProfileFailure) {
          return _ErrorView(
            error: state.error,
            onRetry: () => context.read<ProfileCubit>().loadProfile(),
          );
        }
        if (state is ProfileSuccess) {
          return _SuccessView(
            profile: state.profile,
            posts: state.posts,
            savedPosts: state.savedPosts,
            tabController: _tabController,
          );
        }
        return const _LoadingView();
      },
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
                onPressed: onRetry,
                child: const Text(
                  'Retry',
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

// ── Success ───────────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final ProfileModel profile;
  final List<PostModel> posts;
  final List<PostModel> savedPosts;
  final TabController tabController;

  const _SuccessView({
    required this.profile,
    required this.posts,
    required this.savedPosts,
    required this.tabController,
  });

  void _navigateToFeed(
    BuildContext context,
    List<PostModel> postsList,
    int index, {
    bool isSavedFeed = false,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ProfileCubit>(),
          child: ProfilePostsFeedPage(
            posts: postsList,
            initialIndex: index,
            postBuilder: (feedCtx, post) {
              return BlocBuilder<ProfileCubit, ProfileState>(
                builder: (context, state) {
                  PostModel latestPost = post;
                  if (state is ProfileSuccess) {
                    if (isSavedFeed) {
                      latestPost = state.savedPosts.firstWhere(
                        (p) => p.id == post.id,
                        orElse: () => state.posts.firstWhere(
                          (p) => p.id == post.id,
                          orElse: () => post,
                        ),
                      );
                    } else {
                      latestPost = state.posts.firstWhere(
                        (p) => p.id == post.id,
                        orElse: () => post,
                      );
                    }
                  }
                  return PostCard(
                    post: latestPost,
                    onLike: () => context.read<ProfileCubit>().toggleLike(latestPost.id),
                    onComment: () => CommentsSheet.show(context, latestPost),
                    onSave: () => context.read<ProfileCubit>().toggleSave(latestPost.id),
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
    final reels = posts.where((p) => p.media.any((m) => m.mediaType == 'video')).toList();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── App bar ──────────────────────────────────────────────────────
          _ProfileAppBar(profile: profile),

          // ── Cover image + avatar ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: ProfileCoverAvatar(
              coverUrl: profile.coverUrl,
              avatarUrl: profile.avatarUrl,
              displayName: profile.displayName,
              isVerified: profile.isVerified,
            ),
          ),

          // ── Name + username + bio ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: ProfileInfoSection(
                displayName: profile.displayName,
                username: profile.username,
                bio: profile.bio,
              ),
            ),
          ),

          // ── Stats ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: ProfileStatsRow(
                followersCount: profile.followersCount,
                followingCount: profile.followingCount,
                auraScore: profile.auraScore,
                onFollowersTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => FollowersPage(userId: profile.id)),
                ),
                onFollowingTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => FollowingPage(userId: profile.id)),
                ),
              ),
            ),
          ),

          // ── Action buttons ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: ProfileActionButtons(
                onEditProfile: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<ProfileCubit>(),
                        child: const EditProfilePage(),
                      ),
                    ),
                  );
                },
                onShare: () {},
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // ── Sticky tab bar ───────────────────────────────────────────────
          SliverPersistentHeader(
            delegate: _TabBarDelegate(controller: tabController),
            pinned: true,
          ),
        ],

        body: TabBarView(
          controller: tabController,
          children: [
            // Grid
            ProfilePostsGrid(
              posts: posts,
              storageKey: 'profile_grid',
              onPostTap: (index) => _navigateToFeed(context, posts, index),
            ),

            // Reels / Videos
            ProfilePostsGrid(
              posts: reels,
              storageKey: 'profile_reels',
              onPostTap: (index) => _navigateToFeed(context, reels, index),
            ),

            // Saved
            ProfilePostsGrid(
              posts: savedPosts,
              storageKey: 'profile_saved',
              onPostTap: (index) => _navigateToFeed(context, savedPosts, index, isSavedFeed: true),
              emptyMessage: 'No saved posts yet',
              emptyIcon: Icons.bookmark_border_rounded,
            ),

            // Tagged (placeholder)
            _EmptyScrollView(
              key: const PageStorageKey('profile_tagged'),
              icon: Icons.person_pin_circle_outlined,
              message: 'No tagged posts',
            ),
          ],
        ),
      ),
    );
  }
}

// ── App bar ───────────────────────────────────────────────────────────────────

class _ProfileAppBar extends StatelessWidget {
  final ProfileModel profile;

  const _ProfileAppBar({required this.profile});

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
        padding: const EdgeInsets.all(9),
        child: CircleAvatar(
          backgroundColor: AppColors.darkSurface,
          backgroundImage: profile.avatarUrl != null
              ? NetworkImage(profile.avatarUrl!)
              : null,
          child: profile.avatarUrl == null
              ? const Icon(Icons.person, color: AppColors.primary, size: 18)
              : null,
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
            Icons.settings_outlined,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<ProfileCubit>(),
                  child: const SettingsPage(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── Sticky tab bar delegate ───────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController controller;

  const _TabBarDelegate({required this.controller});

  @override
  double get minExtent => kProfileTabBarHeight;

  @override
  double get maxExtent => kProfileTabBarHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      ProfileTabBar(controller: controller);

  @override
  bool shouldRebuild(_TabBarDelegate old) => controller != old.controller;
}

// ── Scrollable empty state ────────────────────────────────────────────────────
// Wrapping in CustomScrollView is required because NestedScrollView expects
// every TabBarView child to be a scrollable widget.

class _EmptyScrollView extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyScrollView({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 52,
                  color: AppColors.textSubtleOnDark.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 14),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textSubtleOnDark,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
