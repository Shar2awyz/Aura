import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/models/post_model.dart';
import '../models/comment_model.dart';
import '../viewmodel/comments_cubit.dart';
import '../viewmodel/comments_state.dart';

class CommentsSheet extends StatefulWidget {
  final PostModel post;

  const CommentsSheet({super.key, required this.post});

  static Future<void> show(BuildContext context, PostModel post) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => CommentsCubit()..loadComments(post.id),
        child: CommentsSheet(post: post),
      ),
    );
  }

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _currentUserId = Supabase.instance.client.auth.currentUser?.id;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: BlocListener<CommentsCubit, CommentsState>(
            listener: (context, state) {
              if (state is CommentsSuccess) {
                widget.post.commentsCount = state.comments.length;
              } else if (state is CommentsSubmitting) {
                widget.post.commentsCount = state.comments.length;
              }
            },
            child: Column(
              children: [
                _buildHandle(),
                _buildHeader(),
                const Divider(color: AppColors.darkBorder, height: 1),
                Expanded(child: _buildCommentsList(scrollController)),
                _buildInput(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          const Text(
            'Comments',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          BlocBuilder<CommentsCubit, CommentsState>(
            builder: (_, state) {
              final count = state is CommentsSuccess
                  ? state.comments.length
                  : state is CommentsSubmitting
                      ? state.comments.length
                      : widget.post.commentsCount;
              return Text(
                '$count',
                style: const TextStyle(
                  color: AppColors.textSubtleOnDark,
                  fontSize: 14,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(ScrollController scrollController) {
    return BlocBuilder<CommentsCubit, CommentsState>(
      builder: (context, state) {
        if (state is CommentsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (state is CommentsFailure) {
          return Center(
            child: Text(
              state.error,
              style: const TextStyle(color: AppColors.textSubtleOnDark),
              textAlign: TextAlign.center,
            ),
          );
        }

        final comments = switch (state) {
          CommentsSuccess(:final comments) => comments,
          CommentsSubmitting(:final comments) => comments,
          _ => <CommentModel>[],
        };

        if (comments.isEmpty) {
          return const Center(
            child: Text(
              'No comments yet.\nBe the first!',
              style: TextStyle(
                color: AppColors.textSubtleOnDark,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: comments.length,
          itemBuilder: (context, index) => _CommentTile(
            comment: comments[index],
            isOwn: comments[index].userId == _currentUserId,
            onDelete: () => context
                .read<CommentsCubit>()
                .deleteComment(comments[index].id),
          ),
        );
      },
    );
  }

  Widget _buildInput(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.of(context).viewInsets.bottom + 8,
        ),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.darkBorder)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Add a comment…',
                  hintStyle: const TextStyle(
                    color: AppColors.textSubtleOnDark,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: AppColors.darkBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(context),
              ),
            ),
            const SizedBox(width: 8),
            BlocBuilder<CommentsCubit, CommentsState>(
              builder: (ctx, state) {
                final isSubmitting = state is CommentsSubmitting;
                return GestureDetector(
                  onTap: isSubmitting ? null : () => _submit(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.logoGradientStart,
                          AppColors.logoGradientEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    context.read<CommentsCubit>().addComment(
          postId: widget.post.id,
          text: text,
          postOwnerId: widget.post.userId,
        );
  }
}

// ── Comment tile ──────────────────────────────────────────────────────────────

class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  final bool isOwn;
  final VoidCallback onDelete;

  const _CommentTile({
    required this.comment,
    required this.isOwn,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.darkBackground,
            backgroundImage: comment.profile.avatarUrl != null
                ? NetworkImage(comment.profile.avatarUrl!)
                : null,
            child: comment.profile.avatarUrl == null
                ? const Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 16,
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.profile.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (comment.profile.isVerified) ...[
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.verified,
                        color: AppColors.primary,
                        size: 12,
                      ),
                    ],
                    const Spacer(),
                    Text(
                      _timeAgo(comment.createdAt),
                      style: const TextStyle(
                        color: AppColors.textSubtleOnDark,
                        fontSize: 11,
                      ),
                    ),
                    if (isOwn) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onDelete,
                        child: const Icon(
                          Icons.delete_outline,
                          color: AppColors.textSubtleOnDark,
                          size: 16,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  comment.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }
}
