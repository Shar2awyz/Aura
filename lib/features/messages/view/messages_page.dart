import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/hive_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../models/chat_model.dart';
import '../viewmodel/messages_cubit.dart';
import '../viewmodel/messages_state.dart';
import 'chat_detail_page.dart';
import 'new_chat_page.dart';

class MessagesPage extends StatelessWidget {
  final PageController? pageController;
  const MessagesPage({super.key, this.pageController});

  @override
  Widget build(BuildContext context) {
    return _MessagesBody(pageController: pageController);
  }
}

class _MessagesBody extends StatefulWidget {
  final PageController? pageController;
  const _MessagesBody({this.pageController});

  @override
  State<_MessagesBody> createState() => _MessagesBodyState();
}

class _MessagesBodyState extends State<_MessagesBody> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(pageController: widget.pageController),
            _SearchBar(controller: _searchController),
            Expanded(
              child: BlocBuilder<MessagesCubit, MessagesState>(
                builder: (context, state) {
                  if (state is MessagesLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    );
                  }
                  if (state is MessagesFailure) {
                    return _ErrorView(error: state.error);
                  }
                  if (state is MessagesSuccess) {
                    return _ChatList(state: state);
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

// ── App bar ───────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final PageController? pageController;
  const _AppBar({this.pageController});

  @override
  Widget build(BuildContext context) {
    final username = Supabase.instance.client.auth.currentUser?.userMetadata?['username'] as String? ?? 'Messages';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          if (pageController != null)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () {
                pageController!.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                );
              },
            ),
          const SizedBox(width: 8),
          Text(
            username,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white70,
            size: 18,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
            onPressed: () {
              final cubit = context.read<MessagesCubit>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: const NewChatPage(),
                  ),
                ),
              ).then((_) => cubit.loadChats());
            },
          ),
        ],
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: const TextStyle(
              color: Colors.white38, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded,
              color: Colors.white38, size: 18),
          filled: true,
          fillColor: const Color(0xFF262626),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (q) => context.read<MessagesCubit>().search(q),
      ),
    );
  }
}

// ── Full scrollable list ──────────────────────────────────────────────────────

class _ChatList extends StatefulWidget {
  final MessagesSuccess state;
  const _ChatList({required this.state});

  @override
  State<_ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<_ChatList> {
  String? _openingUserId;

  Future<void> _openChatWithUser(Map<String, dynamic> user) async {
    final userId = user['id'] as String;
    if (mounted) {
      setState(() => _openingUserId = userId);
    }

    final cubit = context.read<MessagesCubit>();
    final chat = await cubit.createOrGetDirectChat(userId);
    if (!mounted) return;
    setState(() => _openingUserId = null);

    if (chat != null) {
      final navigator = Navigator.of(context);
      await navigator.push(
        MaterialPageRoute(builder: (_) => ChatDetailPage(chat: chat)),
      );
      if (mounted) {
        cubit.loadChats();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open chat. Please check database permissions.'),
            backgroundColor: AppColors.darkSurface,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dmChats =
        widget.state.chats.where((c) => !c.isGroup && c.otherUser != null).toList();

    // Fetch local saved users from Hive
    final localSavedUsers = HiveStorage.getSavedUsers();

    // Filter local saved users by search query if present
    final query = widget.state.searchQuery.toLowerCase();
    final filteredLocalUsers = localSavedUsers.where((u) {
      final username = (u['username'] as String? ?? '').toLowerCase();
      final fullName = (u['full_name'] as String? ?? '').toLowerCase();
      return username.contains(query) || fullName.contains(query);
    }).toList();

    return CustomScrollView(
      slivers: [
        // ── Active contacts row ────────────────────────────────────────────
        SliverToBoxAdapter(
          child: SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: dmChats.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const _ContactBubble(
                    imageUrl: null,
                    label: 'Your Aura',
                    isYou: true,
                  );
                }
                final chat = dmChats[index - 1];
                return _ContactBubble(
                  imageUrl: chat.displayAvatar,
                  label: chat.otherUser!.username,
                  hasUnread: chat.unreadCount > 0,
                  onTap: () => _openChat(context, chat),
                );
              },
            ),
          ),
        ),

        // ── Local Contacts Section ──────────────────────────────────────────
        if (filteredLocalUsers.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Local Contacts',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final user = filteredLocalUsers[index];
                final userId = user['id'] as String;
                final isOpening = _openingUserId == userId;
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.darkBorder,
                    backgroundImage: user['avatar_url'] != null &&
                            (user['avatar_url'] as String).isNotEmpty
                        ? NetworkImage(user['avatar_url'] as String)
                        : null,
                    child: user['avatar_url'] == null ||
                            (user['avatar_url'] as String).isEmpty
                        ? const Icon(Icons.person,
                            color: AppColors.primary, size: 22)
                        : null,
                  ),
                  title: Text(
                    user['username'] as String? ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: user['full_name'] != null &&
                          (user['full_name'] as String).isNotEmpty
                      ? Text(
                          user['full_name'] as String,
                          style: const TextStyle(
                              color: AppColors.textSubtleOnDark,
                              fontSize: 12),
                        )
                      : null,
                  trailing: isOpening
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.primary, strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white30, size: 14),
                  onTap: isOpening ? null : () => _openChatWithUser(user),
                );
              },
              childCount: filteredLocalUsers.length,
            ),
          ),
        ],

        // ── Section label ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Recent',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // ── Chat tiles ─────────────────────────────────────────────────────
        if (widget.state.filteredChats.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text(
                'No conversations yet.\nTap the edit button to start one.',
                style: TextStyle(color: AppColors.textSubtleOnDark),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _ChatTile(chat: widget.state.filteredChats[index]),
              childCount: widget.state.filteredChats.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  void _openChat(BuildContext context, ChatModel chat) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatDetailPage(chat: chat)),
    );
  }
}

// ── Contact bubble (story row) ────────────────────────────────────────────────

class _ContactBubble extends StatelessWidget {
  final String? imageUrl;
  final String label;
  final bool isYou;
  final bool hasUnread;
  final VoidCallback? onTap;

  const _ContactBubble({
    this.imageUrl,
    required this.label,
    this.isYou = false,
    this.hasUnread = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                isYou
                    ? _DashedAddCircle()
                    : _GradientAvatar(imageUrl: imageUrl),
                if (hasUnread)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.darkBackground, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedAddCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 67,
      height: 67,
      child: CustomPaint(
        painter: _DashedCirclePainter(color: AppColors.darkBorder),
        child: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: AppColors.darkSurface,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.add, color: AppColors.primary, size: 26),
          ),
        ),
      ),
    );
  }
}

class _GradientAvatar extends StatelessWidget {
  final String? imageUrl;
  const _GradientAvatar({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 67,
      height: 67,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF00E5FF), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(2.5),
      child: CircleAvatar(
        backgroundColor: AppColors.darkBackground,
        backgroundImage:
            imageUrl != null ? NetworkImage(imageUrl!) : null,
        child: imageUrl == null
            ? const Icon(Icons.person, color: AppColors.primary, size: 24)
            : null,
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  const _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;
    const dashCount = 18;
    const gap = 0.4;
    final dashLength = (2 * pi / dashCount) * (1 - gap);
    for (var i = 0; i < dashCount; i++) {
      final startAngle = i * (2 * pi / dashCount);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashLength,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}

// ── Chat tile ─────────────────────────────────────────────────────────────────

class _ChatTile extends StatelessWidget {
  final ChatModel chat;
  const _ChatTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    final isUnread = chat.unreadCount > 0;
    return GestureDetector(
      onTap: () {
        final cubit = context.read<MessagesCubit>();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatDetailPage(chat: chat)),
        ).then((_) => cubit.loadChats());
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _avatar(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.displayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessagePreview,
                          style: TextStyle(
                            color: isUnread ? Colors.white : Colors.white60,
                            fontSize: 13,
                            fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '· ${_timeAgo(chat.updatedAt)}',
                        style: TextStyle(
                          color: isUnread ? Colors.white70 : Colors.white38,
                          fontSize: 13,
                          fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF3797EF),
                  shape: BoxShape.circle,
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChatDetailPage(chat: chat)),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _avatar() {
    final url = chat.displayAvatar;
    if (chat.isGroup) {
      return Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
            color: AppColors.darkBorder, shape: BoxShape.circle),
        child: const Icon(Icons.group_rounded,
            color: AppColors.primary, size: 26),
      );
    }
    return Stack(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.darkBorder,
          backgroundImage: url != null ? NetworkImage(url) : null,
          child: url == null
              ? const Icon(Icons.person,
                  color: AppColors.primary, size: 26)
              : null,
        ),
        Positioned(
          right: 1,
          bottom: 1,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.black.withOpacity(0.4), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[time.weekday - 1];
    }
    return '${time.day}/${time.month}';
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.primary, size: 48),
            const SizedBox(height: 12),
            Text(
              error,
              style:
                  const TextStyle(color: AppColors.textSubtleOnDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  context.read<MessagesCubit>().loadChats(),
              child: const Text('Retry',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}
