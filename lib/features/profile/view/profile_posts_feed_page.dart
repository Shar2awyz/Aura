import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/models/post_model.dart';

class ProfilePostsFeedPage extends StatefulWidget {
  final List<PostModel> posts;
  final int initialIndex;
  final Widget Function(BuildContext context, PostModel post) postBuilder;

  const ProfilePostsFeedPage({
    super.key,
    required this.posts,
    required this.initialIndex,
    required this.postBuilder,
  });

  @override
  State<ProfilePostsFeedPage> createState() => _ProfilePostsFeedPageState();
}

class _ProfilePostsFeedPageState extends State<ProfilePostsFeedPage> {
  late final ScrollController _scrollController;
  late final List<GlobalKey> _itemKeys;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _itemKeys = List.generate(widget.posts.length, (_) => GlobalKey());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialIndex >= 0 && widget.initialIndex < widget.posts.length) {
        final targetContext = _itemKeys[widget.initialIndex].currentContext;
        if (targetContext != null) {
          Scrollable.ensureVisible(
            targetContext,
            alignment: 0.0,
            duration: Duration.zero,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        surfaceTintColor: Colors.transparent,
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
        title: const Text(
          'Posts',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        controller: _scrollController,
        cacheExtent: 99999,
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: widget.posts.length,
        itemBuilder: (context, index) {
          final post = widget.posts[index];
          return Container(
            key: _itemKeys[index],
            child: widget.postBuilder(context, post),
          );
        },
      ),
    );
  }
}
