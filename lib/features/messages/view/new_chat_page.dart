import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/hive_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../viewmodel/messages_cubit.dart';
import 'chat_detail_page.dart';

class NewChatPage extends StatefulWidget {
  const NewChatPage({super.key});

  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String? _creatingForUserId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    final results = await context.read<MessagesCubit>().searchUsers(query);
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
    }
  }

  Future<void> _openChat(Map<String, dynamic> user) async {
    final userId = user['id'] as String;
    setState(() => _creatingForUserId = userId);

    final cubit = context.read<MessagesCubit>();

    // Save to local storage using Hive
    await HiveStorage.saveUser(user);

    final chat = await cubit.createOrGetDirectChat(userId);
    if (!mounted) return;
    setState(() => _creatingForUserId = null);
    if (chat != null) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatDetailPage(chat: chat)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open chat. Please check database permissions.'),
          backgroundColor: AppColors.darkSurface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Message',
          style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style:
                  const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search people...',
                hintStyle: const TextStyle(
                    color: AppColors.textSubtleOnDark, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textSubtleOnDark, size: 18),
                filled: true,
                fillColor: AppColors.darkSurface,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 13),
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
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1),
                ),
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary))
                : _results.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'Search for someone to message'
                              : 'No users found',
                          style: const TextStyle(
                              color: AppColors.textSubtleOnDark),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (_, index) {
                          final user = _results[index];
                          final userId = user['id'] as String;
                          final isCreating =
                              _creatingForUserId == userId;
                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 4),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.darkBorder,
                              backgroundImage:
                                  user['avatar_url'] != null
                                      ? NetworkImage(
                                          user['avatar_url'] as String)
                                      : null,
                              child: user['avatar_url'] == null
                                  ? const Icon(Icons.person,
                                      color: AppColors.primary,
                                      size: 22)
                                  : null,
                            ),
                            title: Text(
                              user['username'] as String? ?? '',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: user['full_name'] != null
                                ? Text(
                                    user['full_name'] as String,
                                    style: const TextStyle(
                                        color:
                                            AppColors.textSubtleOnDark,
                                        fontSize: 12),
                                  )
                                : null,
                            trailing: isCreating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                        strokeWidth: 2),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF6366F1),
                                          Color(0xFFA855F7)
                                        ],
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Message',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                            onTap: isCreating ? null : () => _openChat(user),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
