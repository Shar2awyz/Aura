import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/models/post_model.dart';
import '../../home/models/profile_model.dart';
import '../../post/view/post_detail_page.dart';
import '../../profile/view/view_profile_page.dart';
import '../viewmodel/search_cubit.dart';
import '../viewmodel/search_state.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchCubit()..loadExplorePosts(),
      child: const _SearchBody(),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _SearchBody extends StatefulWidget {
  const _SearchBody();

  @override
  State<_SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<_SearchBody> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            _SearchBar(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: (q) => context.read<SearchCubit>().searchUsers(q),
              onClear: () {
                _controller.clear();
                _focusNode.unfocus();
                context.read<SearchCubit>().loadExplorePosts();
              },
            ),
            Expanded(
              child: BlocBuilder<SearchCubit, SearchState>(
                builder: (context, state) {
                  if (state is SearchLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    );
                  }
                  if (state is SearchFailure) {
                    return _ErrorView(
                      error: state.error,
                      onRetry: () =>
                          context.read<SearchCubit>().loadExplorePosts(),
                    );
                  }
                  if (state is SearchExploreSuccess) {
                    return _ExploreGrid(posts: state.posts);
                  }
                  if (state is SearchUsersSuccess) {
                    return _UserResults(users: state.users);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search accounts...',
          hintStyle: const TextStyle(
            color: AppColors.textSubtleOnDark,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSubtleOnDark,
            size: 20,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, _) => value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSubtleOnDark,
                      size: 18,
                    ),
                    onPressed: onClear,
                  )
                : const SizedBox.shrink(),
          ),
          filled: true,
          fillColor: AppColors.darkSurface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: AppColors.primary, width: 1),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

// ── Explore grid ──────────────────────────────────────────────────────────────

class _ExploreGrid extends StatelessWidget {
  final List<PostModel> posts;

  const _ExploreGrid({required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const _EmptyState(
        icon: Icons.explore_outlined,
        message: 'No public posts yet',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) => _GridTile(post: posts[index]),
    );
  }
}

class _GridTile extends StatelessWidget {
  final PostModel post;

  const _GridTile({required this.post});

  @override
  Widget build(BuildContext context) {
    final media = post.media.first;
    final isVideo = media.mediaType == 'video';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostDetailPage(postId: post.id),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            media.mediaUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, _) =>
                const ColoredBox(color: AppColors.darkSurface),
          ),
          if (isVideo)
            const Positioned(
              top: 6,
              right: 6,
              child: Icon(
                Icons.play_circle_fill_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          if (post.media.length > 1)
            const Positioned(
              top: 6,
              right: 6,
              child: Icon(
                Icons.collections_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}

// ── User search results ───────────────────────────────────────────────────────

class _UserResults extends StatelessWidget {
  final List<ProfileModel> users;

  const _UserResults({required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const _EmptyState(
        icon: Icons.person_search_outlined,
        message: 'No accounts found',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length,
      separatorBuilder: (_, _) => const Divider(
        color: AppColors.darkBorder,
        height: 1,
        indent: 72,
      ),
      itemBuilder: (_, index) => _UserTile(user: users[index]),
    );
  }
}

class _UserTile extends StatelessWidget {
  final ProfileModel user;

  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ViewProfilePage(userId: user.id),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.darkSurface,
        backgroundImage:
            user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
        child: user.avatarUrl == null
            ? const Icon(Icons.person, color: AppColors.primary, size: 22)
            : null,
      ),
      title: Row(
        children: [
          Text(
            user.username,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (user.isVerified) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.verified_rounded,
              color: AppColors.primary,
              size: 14,
            ),
          ],
        ],
      ),
      subtitle: user.fullName != null
          ? Text(
              user.fullName!,
              style: const TextStyle(
                color: AppColors.textSubtleOnDark,
                fontSize: 13,
              ),
            )
          : null,
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}
