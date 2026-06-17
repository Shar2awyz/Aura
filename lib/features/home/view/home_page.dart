import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../comments/view/comments_sheet.dart';
import '../../messages/viewmodel/messages_cubit.dart';
import '../../messages/viewmodel/messages_state.dart';
import '../../notifications/viewmodel/notifications_cubit.dart';
import '../../notifications/viewmodel/notifications_state.dart';
import '../../notifications/view/notifications_page.dart';
import '../models/post_model.dart';
import '../viewmodel/feed_cubit.dart';
import '../viewmodel/feed_state.dart';
import '../widgets/post_card.dart';
import '../widgets/stories_row.dart';

class HomePage extends StatelessWidget {
  final PageController? pageController;
  const HomePage({super.key, this.pageController});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FeedCubit()..loadFeed(),
      child: _HomeBody(pageController: pageController),
    );
  }
}

class _HomeBody extends StatefulWidget {
  final PageController? pageController;
  const _HomeBody({this.pageController});

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            _buildStoriesSection(),
            _buildFeedSection(),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.darkBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: BlocBuilder<FeedCubit, FeedState>(
          builder: (context, state) {
            final avatarUrl = state is FeedSuccess
                ? state.currentUserProfile?.avatarUrl
                : null;
            return CircleAvatar(
              backgroundColor: AppColors.darkSurface,
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? const Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 18,
                    )
                  : null,
            );
          },
        ),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [AppColors.logoGradientStart, AppColors.logoGradientEnd],
        ).createShader(bounds),
        child: const Text(
          'Aura',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            _isGridView ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
            color: Colors.white,
          ),
          onPressed: () => setState(() => _isGridView = !_isGridView),
        ),
        BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) {
            int unreadCount = 0;
            if (state is NotificationsSuccess) {
              unreadCount = state.unreadCount;
            }
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {
                    final cubit = context.read<NotificationsCubit>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: cubit,
                          child: const NotificationsPage(),
                        ),
                      ),
                    );
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF3B30),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        BlocBuilder<MessagesCubit, MessagesState>(
          builder: (context, state) {
            bool hasUnread = false;
            if (state is MessagesSuccess) {
              hasUnread = state.chats.any((chat) => chat.unreadCount > 0);
            }
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.messenger_outline_rounded, color: Colors.white),
                  onPressed: () {
                    widget.pageController?.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
                if (hasUnread)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildStoriesSection() {
    return SliverToBoxAdapter(
      child: BlocBuilder<FeedCubit, FeedState>(
        builder: (context, state) {
          if (state is FeedSuccess) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                StoriesRow(
                  stories: state.stories,
                  currentUserProfile: state.currentUserProfile,
                ),
                const SizedBox(height: 4),
              ],
            );
          }
          return Column(
            children: [
              const SizedBox(height: 12),
              _StoriesPlaceholder(),
              const SizedBox(height: 4),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeedSection() {
    return BlocBuilder<FeedCubit, FeedState>(
      builder: (context, state) {
        if (state is FeedLoading) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (state is FeedFailure) {
          return SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.primary,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.error,
                      style: const TextStyle(
                        color: AppColors.textSubtleOnDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.read<FeedCubit>().loadFeed(),
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

        if (state is FeedSuccess) {
          if (state.posts.isEmpty) {
            return const SliverFillRemaining(
              child: Center(
                child: Text(
                  'No posts yet.\nFollow people to see their Aura.',
                  style: TextStyle(
                    color: AppColors.textSubtleOnDark,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (_isGridView) {
            return SliverPadding(
              padding: const EdgeInsets.all(2),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = state.posts[index];
                    return _FeedGridItem(post: post);
                  },
                  childCount: state.posts.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
              ),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = state.posts[index];
                return PostCard(
                  post: post,
                  onLike: () => context.read<FeedCubit>().toggleLike(post.id),
                  onComment: () async {
                    await CommentsSheet.show(context, post);
                    if (mounted) setState(() {});
                  },
                  onSave: () => context.read<FeedCubit>().toggleSave(post.id),
                );
              },
              childCount: state.posts.length,
            ),
          );
        }

        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }
}

class _FeedGridItem extends StatelessWidget {
  final PostModel post;
  const _FeedGridItem({required this.post});

  @override
  Widget build(BuildContext context) {
    final firstMedia = post.media.isNotEmpty ? post.media.first : null;
    return GestureDetector(
      onTap: () => CommentsSheet.show(context, post),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (firstMedia != null)
            Image.network(
              firstMedia.mediaUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: AppColors.darkSurface),
            )
          else
            const ColoredBox(color: AppColors.darkSurface),
          if (post.media.length > 1)
            const Positioned(
              top: 6,
              right: 6,
              child: Icon(Icons.collections, color: Colors.white, size: 16),
            ),
          if (firstMedia?.mediaType == 'video')
            const Positioned(
              top: 6,
              right: 6,
              child: Icon(Icons.play_circle_outline, color: Colors.white, size: 16),
            ),
        ],
      ),
    );
  }
}

class _StoriesPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (_, _) => SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 67,
                height: 67,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.darkSurface,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 48,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
