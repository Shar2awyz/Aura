import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../viewmodel/chat_cubit.dart';
import '../viewmodel/chat_state.dart';

class ChatDetailPage extends StatelessWidget {
  final ChatModel chat;
  const ChatDetailPage({super.key, required this.chat});

  static String? activeChatId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatCubit(chat.id)..loadMessages(),
      child: _ChatBody(chat: chat),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _ChatBody extends StatefulWidget {
  final ChatModel chat;
  const _ChatBody({required this.chat});

  @override
  State<_ChatBody> createState() => _ChatBodyState();
}

class _ChatBodyState extends State<_ChatBody> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    ChatDetailPage.activeChatId = widget.chat.id;
    _inputController.addListener(() {
      final has = _inputController.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
      if (has) context.read<ChatCubit>().onTypingChanged(true);
    });
  }

  @override
  void dispose() {
    if (ChatDetailPage.activeChatId == widget.chat.id) {
      ChatDetailPage.activeChatId = null;
    }
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatCubit, ChatState>(
              listenWhen: (prev, curr) {
                if (prev is ChatSuccess && curr is ChatSuccess) {
                  return curr.messages.length > prev.messages.length;
                }
                return false;
              },
              listener: (_, _) => _scrollToBottom(),
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (state is ChatFailure) {
                  return Center(
                    child: Text(state.error,
                        style: const TextStyle(
                            color: Colors.white60)),
                  );
                }
                if (state is ChatSuccess) {
                  return _MessageArea(
                    state: state,
                    scrollController: _scrollController,
                    chat: widget.chat,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          // Typing indicator
          BlocBuilder<ChatCubit, ChatState>(
            builder: (_, state) {
              if (state is ChatSuccess && state.typingUsernames.isNotEmpty) {
                final names = state.typingUsernames.join(', ');
                return Container(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  color: Colors.black,
                  child: Row(
                    children: [
                      _TypingDots(),
                      const SizedBox(width: 8),
                      Text(
                        '$names is typing...',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Reply preview bar
          BlocBuilder<ChatCubit, ChatState>(
            builder: (_, state) {
              if (state is ChatSuccess && state.replyToMessage != null) {
                return _ReplyBar(
                  message: state.replyToMessage!,
                  onCancel: () => context.read<ChatCubit>().clearReply(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          _InputBar(
            controller: _inputController,
            hasText: _hasText,
            onSendText: _sendText,
            onAttachment: _showAttachmentOptions,
            onCameraPressed: _pickImage,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF262626),
            backgroundImage: widget.chat.displayAvatar != null
                ? NetworkImage(widget.chat.displayAvatar!)
                : null,
            child: widget.chat.displayAvatar == null
                ? Icon(
                    widget.chat.isGroup ? Icons.group_rounded : Icons.person,
                    color: Colors.white,
                    size: 16,
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.chat.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                BlocBuilder<ChatCubit, ChatState>(
                  builder: (_, state) {
                    final isTyping = state is ChatSuccess &&
                        state.typingUsernames.isNotEmpty;
                    return Text(
                      isTyping ? 'typing...' : 'Active now',
                      style: TextStyle(
                        color: isTyping
                            ? const Color(0xFF22C55E)
                            : Colors.white54,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call_outlined, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.videocam_outlined, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Future<void> _sendText() async {
    final text = _inputController.text;
    if (text.trim().isEmpty) return;
    _inputController.clear();
    context.read<ChatCubit>().onTypingChanged(false);
    await context.read<ChatCubit>().sendText(text);
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;
    final picked = result.files.first;
    await context.read<ChatCubit>().sendMedia(
          filePath: picked.path,
          fileBytes: picked.bytes,
          messageType: 'image',
          fileName: picked.name,
        );
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;
    final picked = result.files.first;
    final messageType = _messageTypeFor(picked.extension ?? '');
    await context.read<ChatCubit>().sendMedia(
          filePath: picked.path,
          fileBytes: picked.bytes,
          messageType: messageType,
          fileName: picked.name,
        );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined, color: Colors.white),
              title:
                  const Text('Photo / Video', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAttachment();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.attach_file_rounded, color: Colors.white),
              title: const Text('File', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAttachment();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_rounded, color: Colors.white),
              title:
                  const Text('Web URL', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _showWebUrlDialog();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showWebUrlDialog() {
    final urlController = TextEditingController();
    String selectedType = 'image';
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Send Web URL',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Paste a direct link:',
                  style:
                      TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'https://example.com/image.jpg',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: AppColors.darkBackground,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: ['image', 'video'].map((type) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Center(
                            child: Text(
                                type[0].toUpperCase() + type.substring(1))),
                        selected: selectedType == type,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.darkBackground,
                        labelStyle: TextStyle(
                          color: selectedType == type
                              ? Colors.white
                              : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (v) {
                          if (v) setDialogState(() => selectedType = type);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                final url = urlController.text.trim();
                if (url.isEmpty) return;
                Navigator.pop(dialogCtx);
                final uri = Uri.tryParse(url);
                final fileName =
                    uri != null && uri.pathSegments.isNotEmpty
                        ? uri.pathSegments.last
                        : 'web_file';
                context.read<ChatCubit>().sendMedia(
                      webUrl: url,
                      messageType: selectedType,
                      fileName: fileName,
                    );
              },
              child: const Text('Send',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  String _messageTypeFor(String ext) {
    const imageExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'};
    const videoExts = {'mp4', 'mov', 'avi', 'mkv', 'webm'};
    const audioExts = {'mp3', 'aac', 'wav', 'ogg', 'm4a'};
    final e = ext.toLowerCase();
    if (imageExts.contains(e)) return 'image';
    if (videoExts.contains(e)) return 'video';
    if (audioExts.contains(e)) return 'audio';
    return 'file';
  }
}

// ── Message area ──────────────────────────────────────────────────────────────

class _MessageArea extends StatelessWidget {
  final ChatSuccess state;
  final ScrollController scrollController;
  final ChatModel chat;

  const _MessageArea({
    required this.state,
    required this.scrollController,
    required this.chat,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id;

    if (state.messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet.\nSay hello! 👋',
          style: TextStyle(color: Colors.white54, height: 1.6),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Find the last message sent by current user (for seen receipt)
    final lastSentIndex = state.messages.indexWhere(
        (m) => m.senderId == currentUserId);

    return Stack(
      children: [
        ListView.builder(
          controller: scrollController,
          reverse: true,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          itemCount: state.messages.length,
          itemBuilder: (context, index) {
            final msg = state.messages[index];
            final isMe = msg.senderId == currentUserId;
            final showAvatar = !isMe &&
                (index == state.messages.length - 1 ||
                    state.messages[index + 1].senderId != msg.senderId);
            final showSeen =
                isMe && index == lastSentIndex && msg.isSeen;
            final showDateSep = _shouldShowDate(state.messages, index);

            // Grouping corner radius logic
            BorderRadius borderRadius = BorderRadius.circular(18);
            
            bool groupedWithAbove = false;
            if (index + 1 < state.messages.length) {
              final aboveMsg = state.messages[index + 1];
              groupedWithAbove = aboveMsg.senderId == msg.senderId &&
                  msg.createdAt.difference(aboveMsg.createdAt).inMinutes < 5 &&
                  !msg.isDeleted && !aboveMsg.isDeleted;
            }

            bool groupedWithBelow = false;
            if (index - 1 >= 0) {
              final belowMsg = state.messages[index - 1];
              groupedWithBelow = belowMsg.senderId == msg.senderId &&
                  belowMsg.createdAt.difference(msg.createdAt).inMinutes < 5 &&
                  !msg.isDeleted && !belowMsg.isDeleted;
            }

            if (isMe) {
              if (groupedWithAbove && groupedWithBelow) {
                borderRadius = const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                );
              } else if (groupedWithAbove) {
                borderRadius = const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(18),
                );
              } else if (groupedWithBelow) {
                borderRadius = const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                );
              }
            } else {
              if (groupedWithAbove && groupedWithBelow) {
                borderRadius = const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                );
              } else if (groupedWithAbove) {
                borderRadius = const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                );
              } else if (groupedWithBelow) {
                borderRadius = const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                );
              }
            }

            return Column(
              children: [
                if (showDateSep) _DateSeparator(date: msg.createdAt),
                _BubbleWrapper(
                  message: msg,
                  isMe: isMe,
                  showAvatar: showAvatar,
                  showSeen: showSeen,
                  borderRadius: borderRadius,
                ),
              ],
            );
          },
        ),
        if (state.isSending)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Uploading...',
                        style: TextStyle(
                            color: AppColors.textSubtleOnDark,
                            fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool _shouldShowDate(List<MessageModel> messages, int index) {
    if (index == messages.length - 1) return true;
    final current = messages[index].createdAt;
    final prev = messages[index + 1].createdAt;
    return !_sameDay(current, prev);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Date separator ────────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(
              child: Divider(color: AppColors.darkBorder, thickness: 0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _format(date),
              style: const TextStyle(
                  color: AppColors.textSubtleOnDark, fontSize: 11),
            ),
          ),
          const Expanded(
              child: Divider(color: AppColors.darkBorder, thickness: 0.5)),
        ],
      ),
    );
  }

  String _format(DateTime d) {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}

// ── Bubble wrapper (handles gestures) ─────────────────────────────────────────

class _BubbleWrapper extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showAvatar;
  final bool showSeen;
  final BorderRadius borderRadius;

  const _BubbleWrapper({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.showSeen,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChatCubit>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: GestureDetector(
        onDoubleTap: message.isDeleted
            ? null
            : () => cubit.reactToMessage(
                message.id, message.reaction == '❤️' ? null : '❤️'),
        onLongPress:
            message.isDeleted ? null : () => _showActionSheet(context, cubit),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe) ...[
                  SizedBox(
                    width: 32,
                    child: showAvatar
                        ? CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFF262626),
                            backgroundImage:
                                message.sender?.avatarUrl != null
                                    ? NetworkImage(message.sender!.avatarUrl!)
                                    : null,
                            child: message.sender?.avatarUrl == null
                                ? const Icon(Icons.person,
                                    color: Colors.white, size: 14)
                                : null,
                          )
                        : null,
                  ),
                  const SizedBox(width: 6),
                ],
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                  ),
                  child: _SwipeToReply(
                    isMe: isMe,
                    onReply: () {
                      HapticFeedback.lightImpact();
                      cubit.setReply(message);
                    },
                    child: _Bubble(
                      message: message,
                      isMe: isMe,
                      borderRadius: borderRadius,
                    ),
                  ),
                ),
              ],
            ),
            // Reaction chip
            if (message.reaction != null && !message.isDeleted)
              Padding(
                padding: EdgeInsets.only(
                  left: isMe ? 0 : 38,
                  right: isMe ? 4 : 0,
                  top: 2,
                ),
                child: GestureDetector(
                  onTap: () => cubit.reactToMessage(message.id, null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF262626),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white10, width: 0.5),
                    ),
                    child: Text(message.reaction!,
                        style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ),
            // Seen receipt
            if (showSeen)
              Padding(
                padding: const EdgeInsets.only(right: 4, top: 2),
                child: const Text(
                  'Seen',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showActionSheet(BuildContext context, ChatCubit cubit) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Floating Quick emoji reactions panel
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF262626),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['❤️', '😂', '😮', '😢', '😡', '👍'].map((emoji) {
                    final isActive = message.reaction == emoji;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        cubit.reactToMessage(
                            message.id, isActive ? null : emoji);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white10
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            ListTile(
              leading:
                  const Icon(Icons.reply_rounded, color: Colors.white),
              title: const Text('Reply',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                cubit.setReply(message);
              },
            ),
            if (message.isText && message.content != null)
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: Colors.white),
                title: const Text('Copy',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(
                      ClipboardData(text: message.content!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied'),
                      duration: Duration(seconds: 1),
                      backgroundColor: Color(0xFF262626),
                    ),
                  );
                },
              ),
            if (message.senderId == currentUserId)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent),
                title: const Text('Unsend',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  cubit.unsendMessage(message.id);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Swipe to Reply Gesture Detector ──────────────────────────────────────────

class _SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;
  final bool isMe;

  const _SwipeToReply({
    required this.child,
    required this.onReply,
    required this.isMe,
  });

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _dragOffset = 0.0;
  static const double _threshold = 50.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRightSwipe = !widget.isMe;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          if (isRightSwipe) {
            _dragOffset = (_dragOffset + details.delta.dx).clamp(0.0, _threshold * 1.5);
          } else {
            _dragOffset = (_dragOffset + details.delta.dx).clamp(-_threshold * 1.5, 0.0);
          }
        });
      },
      onHorizontalDragEnd: (details) {
        if (_dragOffset.abs() >= _threshold) {
          widget.onReply();
        }
        _controller.forward(from: _dragOffset.abs() / (_threshold * 1.5)).then((_) {
          setState(() {
            _dragOffset = 0.0;
            _controller.reset();
          });
        });
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final offset = _controller.isAnimating
              ? (isRightSwipe
                  ? (1.0 - _controller.value) * _dragOffset
                  : (1.0 - _controller.value) * _dragOffset)
              : _dragOffset;

          return Stack(
            clipBehavior: Clip.none,
            alignment: isRightSwipe ? Alignment.centerLeft : Alignment.centerRight,
            children: [
              Positioned(
                left: isRightSwipe ? -35 : null,
                right: isRightSwipe ? null : -35,
                child: Opacity(
                  opacity: (offset.abs() / _threshold).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: (offset.abs() / _threshold).clamp(0.5, 1.0),
                    child: const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.reply_rounded, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(offset, 0),
                child: widget.child,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Bubble content ────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final BorderRadius borderRadius;
  
  const _Bubble({
    required this.message,
    required this.isMe,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) return _DeletedBubble(isMe: isMe, borderRadius: borderRadius);

    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (message.replyToMessage != null)
          _ReplyPreviewInBubble(
              reply: message.replyToMessage!, isMe: isMe),
        _contentBubble(context),
      ],
    );
  }

  Widget _contentBubble(BuildContext context) {
    if (message.isImage && message.mediaUrl != null) {
      return _ImageBubble(
          url: message.mediaUrl!,
          isMe: isMe,
          hasReply: message.replyToMessage != null,
          borderRadius: borderRadius);
    }
    if ((message.isVideo || message.isAudio || message.isFile) &&
        message.mediaUrl != null) {
      return _FileBubble(message: message, isMe: isMe, borderRadius: borderRadius);
    }
    return _TextBubble(
      text: message.content ?? '',
      isMe: isMe,
      time: _formatTime(message.createdAt),
      hasReply: message.replyToMessage != null,
      borderRadius: borderRadius,
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }
}

class _DeletedBubble extends StatelessWidget {
  final bool isMe;
  final BorderRadius borderRadius;
  const _DeletedBubble({required this.isMe, required this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: borderRadius,
        border: Border.all(color: Colors.white10, width: 0.5),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block_rounded,
              color: Colors.white38, size: 14),
          SizedBox(width: 6),
          Text(
            'Message unsent',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// Replied-to preview shown inside the bubble
class _ReplyPreviewInBubble extends StatelessWidget {
  final MessageModel reply;
  final bool isMe;
  const _ReplyPreviewInBubble(
      {required this.reply, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white38 : const Color(0xFF3797EF),
            width: 2.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reply.sender?.username ?? 'User',
            style: TextStyle(
              color: isMe ? Colors.white70 : const Color(0xFF3797EF),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            reply.replyPreview,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TextBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;
  final bool hasReply;
  final BorderRadius borderRadius;

  const _TextBubble({
    required this.text,
    required this.isMe,
    required this.time,
    this.hasReply = false,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: isMe
            ? const LinearGradient(
                colors: [Color(0xFF818CF8), Color(0xFFC084FC), Color(0xFFF472B6)],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              )
            : null,
        color: isMe ? null : const Color(0xFF262626),
        borderRadius: hasReply
            ? borderRadius.copyWith(
                topLeft: const Radius.circular(4),
                topRight: const Radius.circular(4),
              )
            : borderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(
              color: isMe
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.white38,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageBubble extends StatelessWidget {
  final String url;
  final bool isMe;
  final bool hasReply;
  final BorderRadius borderRadius;
  
  const _ImageBubble({
    required this.url,
    required this.isMe,
    this.hasReply = false,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: hasReply
          ? borderRadius.copyWith(
              topLeft: const Radius.circular(4),
              topRight: const Radius.circular(4),
            )
          : borderRadius,
      child: Image.network(
        url,
        width: 220,
        height: 220,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                width: 220,
                height: 220,
                color: const Color(0xFF262626),
                child: const Center(
                  child: CircularProgressIndicator(
                      color: Colors.white24, strokeWidth: 2),
                ),
              ),
      ),
    );
  }
}

class _FileBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final BorderRadius borderRadius;
  
  const _FileBubble({
    required this.message,
    required this.isMe,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final icon = message.isVideo
        ? Icons.videocam_rounded
        : message.isAudio
            ? Icons.audiotrack_rounded
            : Icons.insert_drive_file_rounded;
    final label = message.fileName ??
        (message.isVideo
            ? 'Video'
            : message.isAudio
                ? 'Audio'
                : 'File');

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: isMe
            ? const LinearGradient(
                colors: [Color(0xFF818CF8), Color(0xFFC084FC), Color(0xFFF472B6)],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              )
            : null,
        color: isMe ? null : const Color(0xFF262626),
        borderRadius: borderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ── Reply preview bar (above input) ──────────────────────────────────────────

class _ReplyBar extends StatelessWidget {
  final MessageModel message;
  final VoidCallback onCancel;

  const _ReplyBar({required this.message, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(
          top: BorderSide(color: AppColors.darkBorder, width: 0.5),
          left: BorderSide(color: AppColors.primary, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${message.sender?.username ?? 'User'}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.replyPreview,
                  style: const TextStyle(
                    color: AppColors.textSubtleOnDark,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded,
                color: AppColors.textSubtleOnDark, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool hasText;
  final VoidCallback onSendText;
  final VoidCallback onAttachment;
  final VoidCallback onCameraPressed;

  const _InputBar({
    required this.controller,
    required this.hasText,
    required this.onSendText,
    required this.onAttachment,
    required this.onCameraPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.paddingOf(context).bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 0.5)),
      ),
      child: Row(
        children: [
          // Blue camera circle button
          GestureDetector(
            onTap: onCameraPressed,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF3797EF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          // Capsule Text Field and other actions inside
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 5,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        hintStyle: TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (!hasText) ...[
                    IconButton(
                      icon: const Icon(Icons.mic_none_rounded, color: Colors.white, size: 22),
                      onPressed: () {},
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.image_outlined, color: Colors.white, size: 22),
                      onPressed: onAttachment,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.sentiment_satisfied_alt_rounded, color: Colors.white, size: 22),
                      onPressed: onAttachment,
                      padding: const EdgeInsets.only(left: 4, right: 12, top: 8, bottom: 8),
                      constraints: const BoxConstraints(),
                    ),
                  ] else ...[
                    GestureDetector(
                      onTap: onSendText,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 4, right: 16, top: 10, bottom: 10),
                        child: Text(
                          'Send',
                          style: TextStyle(
                            color: Color(0xFF3797EF),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Typing dots animation ─────────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final offset = ((_controller.value * 3) - i).clamp(0.0, 1.0);
            final scale = 1.0 + 0.4 * (offset < 0.5 ? offset * 2 : (1 - offset) * 2);
            return Transform.scale(
              scale: scale,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.textSubtleOnDark,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
