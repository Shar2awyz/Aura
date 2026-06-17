import 'dart:async';
import 'package:flutter/material.dart';
import 'package:untitled/core/theme/app_colors.dart';

class CustomerServicePage extends StatefulWidget {
  const CustomerServicePage({super.key});

  @override
  State<CustomerServicePage> createState() => _CustomerServicePageState();
}

class _CustomerServicePageState extends State<CustomerServicePage> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Add initial welcome message
    _messages.add(
      const _ChatMessage(
        text: "Hello! Welcome to Aura Customer Service. I am your Aura Support Assistant. How can I help you today?",
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _scrollToBottom();

    // Simulate bot thinking and typing
    Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;

      final reply = _generateBotResponse(text);
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(text: reply, isUser: false));
      });
      _scrollToBottom();
    });
  }

  String _generateBotResponse(String input) {
    final cleanInput = input.toLowerCase();

    if (cleanInput.contains('private')) {
      return "🔒 To make your account private, go to Settings and toggle 'Private Account'. When active, only approved followers will be able to see your profile details, feeds, and reels.";
    } else if (cleanInput.contains('dark') || cleanInput.contains('light') || cleanInput.contains('theme')) {
      return "🎨 You can toggle the app theme instantly under App Preferences in Settings. Switching the 'Dark Mode' toggle updates the application between our deep neon night style and a crisp purple light theme.";
    } else if (cleanInput.contains('notification')) {
      return "🔕 If you wish to suspend alerts, toggle 'Stop Notifications' in Settings. This will immediately intercept and suppress any local or push notifications from popping up on your screen.";
    } else if (cleanInput.contains('switch') || cleanInput.contains('account')) {
      return "👥 Under the 'ACCOUNTS' section in Settings, you will see a list of accounts saved on this device. Tap the switch icon next to any account to authenticate instantly, or tap 'Add Account' to sign in to a new profile.";
    } else if (cleanInput.contains('logout') || cleanInput.contains('log out') || cleanInput.contains('sign out')) {
      return "🚪 To sign out of your current session, scroll to the bottom of the Settings page and tap the red 'Log Out Session' button. This will log you out of Supabase and redirect you to the LoginPage.";
    } else if (cleanInput.contains('hi') || cleanInput.contains('hello') || cleanInput.contains('hey')) {
      return "👋 Hello there! I'm Aura's virtual support assistant. I can help answer questions about changing themes, switching accounts, making your profile private, or setting up notification preferences. What can I help you with?";
    } else if (cleanInput.contains('help') || cleanInput.contains('support') || cleanInput.contains('assist')) {
      return "💡 I can guide you through using the settings page! Ask me about:\n• How to switch accounts\n• Activating private mode\n• Stopping notifications\n• Toggling light/dark mode";
    }

    return "📋 Thank you for your message! Since this is a prototype, I have logged your request: \"$input\". Our live customer support agents will review this log and respond to you as soon as possible. Let me know if you have any questions about Aura's features in the meantime!";
  }

  @override
  Widget build(BuildContext context) {
    final isThemeDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isThemeDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isThemeDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isThemeDark ? Colors.white : AppColors.textOnLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 20),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: isThemeDark ? AppColors.darkBackground : Colors.white, width: 1.5),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aura Bot',
                  style: TextStyle(
                    color: isThemeDark ? Colors.white : AppColors.textOnLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Text(
                  'Online Support',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg, isThemeDark);
              },
            ),
          ),
          if (_isTyping) _buildTypingIndicator(isThemeDark),
          _buildInputArea(isThemeDark),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message, bool isThemeDark) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isUser
              ? AppColors.primary
              : (isThemeDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: message.isUser ? const Radius.circular(20) : Radius.zero,
            bottomRight: message.isUser ? Radius.zero : const Radius.circular(20),
          ),
          border: Border.all(
            color: message.isUser
                ? Colors.transparent
                : (isThemeDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1,
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser
                ? Colors.white
                : (isThemeDark ? Colors.white : AppColors.textOnLight),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isThemeDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Aura Bot is thinking',
              style: TextStyle(
                color: isThemeDark ? AppColors.textSubtleOnDark : AppColors.textSubtleOnLight,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 6),
            _TypingDot(isThemeDark: isThemeDark, delay: 0),
            _TypingDot(isThemeDark: isThemeDark, delay: 200),
            _TypingDot(isThemeDark: isThemeDark, delay: 400),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isThemeDark) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 12),
      decoration: BoxDecoration(
        color: isThemeDark ? AppColors.darkBackground : AppColors.lightBackground,
        border: Border(
          top: BorderSide(
            color: isThemeDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              onSubmitted: (_) => _handleSend(),
              style: TextStyle(color: isThemeDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: isThemeDark ? Colors.white54 : Colors.black54),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                filled: true,
                fillColor: isThemeDark ? AppColors.darkSurface : Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: isThemeDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary,
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              onPressed: _handleSend,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}

class _TypingDot extends StatefulWidget {
  final bool isThemeDark;
  final int delay;

  const _TypingDot({required this.isThemeDark, required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = Tween<double>(begin: 0, end: 4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Timer(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          transform: Matrix4.translationValues(0, -_animation.value, 0),
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: widget.isThemeDark ? AppColors.textSubtleOnDark : AppColors.textSubtleOnLight,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
