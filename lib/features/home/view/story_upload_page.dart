import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/blob_url_helper.dart' as blob_helper;
import '../repo/feed_repo.dart';
import '../viewmodel/feed_cubit.dart';

class StoryUploadPage extends StatefulWidget {
  final FeedCubit feedCubit;

  const StoryUploadPage({super.key, required this.feedCubit});

  @override
  State<StoryUploadPage> createState() => _StoryUploadPageState();
}

class _StoryUploadPageState extends State<StoryUploadPage> {
  String? _filePath;
  Uint8List? _fileBytes;
  String? _fileName;
  String? _webUrl;
  String _mediaType = 'image';
  bool _isUploading = false;
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  final _captionController = TextEditingController();
  final _repo = FeedRepo();

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initVideo() async {
    _videoController?.dispose();
    _videoController = null;
    _videoInitialized = false;

    if (_webUrl != null) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(_webUrl!));
    } else if (_filePath != null && !kIsWeb) {
      _videoController = VideoPlayerController.file(File(_filePath!));
    } else if (_fileBytes != null) {
      final blobUrl = blob_helper.createBlobUrl(_fileBytes!);
      if (blobUrl != null) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(blobUrl));
      }
    }

    if (_videoController != null) {
      try {
        await _videoController!.initialize();
        _videoController!.setLooping(true);
        _videoController!.play();
        if (mounted) {
          setState(() {
            _videoInitialized = true;
          });
        }
      } catch (e) {
        debugPrint('Error initializing preview video in stories: $e');
      }
    }
  }

  Future<void> _pickMedia(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: type == 'image' ? FileType.image : FileType.video,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;

    setState(() {
      _filePath = file.path;
      _fileBytes = file.bytes;
      _fileName = file.name;
      _webUrl = null;
      _mediaType = type;
    });

    if (type == 'video') {
      _initVideo();
    }
  }

  void _showWebUrlDialog() {
    final urlController = TextEditingController();
    String selectedType = 'image';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.darkSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Add Story from Web URL',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Paste a direct link to an image or video:',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'https://example.com/story.jpg',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: AppColors.darkBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Media Type:',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Image')),
                          selected: selectedType == 'image',
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.darkBackground,
                          labelStyle: TextStyle(
                            color: selectedType == 'image' ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            if (val) setDialogState(() => selectedType = 'image');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Video')),
                          selected: selectedType == 'video',
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.darkBackground,
                          labelStyle: TextStyle(
                            color: selectedType == 'video' ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            if (val) setDialogState(() => selectedType = 'video');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: () {
                    final url = urlController.text.trim();
                    if (url.isEmpty) return;
                    Navigator.pop(context);
                    setState(() {
                      _webUrl = url;
                      _filePath = null;
                      _fileBytes = null;
                      _fileName = null;
                      _mediaType = selectedType;
                    });
                    if (selectedType == 'video') {
                      _initVideo();
                    }
                  },
                  child: const Text(
                    'Next',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _share() async {
    final hasLocalMedia = _filePath != null || _fileBytes != null;
    final hasWebMedia = _webUrl != null && _webUrl!.trim().isNotEmpty;
    if ((!hasLocalMedia && !hasWebMedia) || _isUploading) return;
    setState(() => _isUploading = true);

    try {
      String? url;
      if (hasWebMedia) {
        url = _webUrl;
      } else {
        url = await CloudinaryService.uploadFile(
          filePath: _filePath,
          fileBytes: _fileBytes,
          fileName: _fileName ?? 'story_file',
          resourceType: _mediaType,
        );
      }
      if (url == null) throw Exception('Upload failed — check Cloudinary config');

      await _repo.uploadStory(
        mediaUrl: url,
        mediaType: _mediaType,
        caption: _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim(),
      );

      if (mounted) {
        widget.feedCubit.refreshStories();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMedia = _filePath != null || _fileBytes != null || _webUrl != null;
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: _buildAppBar(hasMedia),
      body: !hasMedia ? _buildPicker() : _buildPreview(),
    );
  }

  AppBar _buildAppBar(bool hasMedia) {
    return AppBar(
      backgroundColor: AppColors.darkBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [AppColors.logoGradientStart, AppColors.logoGradientEnd],
        ).createShader(bounds),
        child: const Text(
          'Your Aura',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        if (hasMedia)
          _isUploading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _share,
                  child: const Text(
                    'Share',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
      ],
    );
  }

  Widget _buildPicker() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 24),
            const Text(
              'Add to Your Aura',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share a photo or video that\ndisappears after 24 hours',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSubtleOnDark,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: _PickerButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Photo',
                    onTap: () => _pickMedia('image'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _PickerButton(
                    icon: Icons.videocam_outlined,
                    label: 'Video',
                    onTap: () => _pickMedia('video'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: _PickerButton(
                icon: Icons.language_rounded,
                label: 'Add from Web URL',
                onTap: _showWebUrlDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewWidget() {
    if (_mediaType == 'video') {
      if (_videoInitialized && _videoController != null) {
        return VideoPlayer(_videoController!);
      } else {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_rounded,
                color: AppColors.primary,
                size: 80,
              ),
              const SizedBox(height: 12),
              Text(
                _fileName ?? _webUrl ?? 'Video',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
    } else {
      if (_fileBytes != null) {
        return Image.memory(_fileBytes!, fit: BoxFit.contain);
      } else if (_filePath != null && !kIsWeb) {
        return Image.file(File(_filePath!), fit: BoxFit.contain);
      } else if (_webUrl != null) {
        return Image.network(
          _webUrl!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image, color: Colors.white30, size: 80),
          ),
        );
      }
      return Container();
    }
  }

  Widget _buildPreview() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildPreviewWidget(),
              Positioned(
                bottom: 12,
                left: 12,
                child: GestureDetector(
                  onTap: () {
                    _videoController?.dispose();
                    setState(() {
                      _filePath = null;
                      _fileBytes = null;
                      _fileName = null;
                      _webUrl = null;
                      _videoController = null;
                      _videoInitialized = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz, color: Colors.white70, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Change',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          color: AppColors.darkSurface,
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: TextField(
            controller: _captionController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Add a caption...',
              hintStyle: const TextStyle(color: AppColors.textSubtleOnDark),
              filled: true,
              fillColor: AppColors.darkBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 36),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
