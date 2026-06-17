import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/blob_url_helper.dart' as blob_helper;
import '../viewmodel/post_creation_cubit.dart';
import '../viewmodel/post_creation_state.dart';

class AddPostPage extends StatefulWidget {
  final String? filePath;
  final Uint8List? fileBytes;
  final String? fileName;
  final String? webUrl;
  final String mediaType; // 'image' or 'video'

  const AddPostPage({
    super.key,
    this.filePath,
    this.fileBytes,
    this.fileName,
    this.webUrl,
    required this.mediaType,
  });

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final _captionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  double _aspectRatio = 1.0;
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    _computeAspectRatio();
    if (widget.mediaType == 'video') {
      _initVideo();
    }
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    _locationCtrl.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initVideo() async {
    if (widget.webUrl != null) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.webUrl!));
    } else if (widget.filePath != null && !kIsWeb) {
      _videoController = VideoPlayerController.file(File(widget.filePath!));
    } else if (widget.fileBytes != null) {
      final blobUrl = blob_helper.createBlobUrl(widget.fileBytes!);
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
            _aspectRatio = _videoController!.value.aspectRatio;
          });
        }
      } catch (e) {
        debugPrint('Error initializing preview video: $e');
      }
    }
  }

  Future<void> _computeAspectRatio() async {
    if (widget.mediaType == 'video') return;
    try {
      Uint8List? bytes;
      if (widget.fileBytes != null) {
        bytes = widget.fileBytes;
      } else if (widget.filePath != null && !kIsWeb) {
        bytes = await File(widget.filePath!).readAsBytes();
      }

      if (bytes != null) {
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        if (mounted) {
          setState(() {
            _aspectRatio = frame.image.width / frame.image.height;
          });
        }
      } else if (widget.webUrl != null) {
        final image = NetworkImage(widget.webUrl!);
        final stream = image.resolve(ImageConfiguration.empty);
        stream.addListener(ImageStreamListener((info, _) {
          if (mounted) {
            setState(() {
              _aspectRatio = info.image.width / info.image.height;
            });
          }
        }));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PostCreationCubit(),
      child: _AddPostPageBody(
        filePath: widget.filePath,
        fileBytes: widget.fileBytes,
        fileName: widget.fileName,
        webUrl: widget.webUrl,
        mediaType: widget.mediaType,
        aspectRatio: _aspectRatio,
        captionCtrl: _captionCtrl,
        locationCtrl: _locationCtrl,
        videoController: _videoController,
        videoInitialized: _videoInitialized,
      ),
    );
  }
}

class _AddPostPageBody extends StatelessWidget {
  final String? filePath;
  final Uint8List? fileBytes;
  final String? fileName;
  final String? webUrl;
  final String mediaType;
  final double aspectRatio;
  final TextEditingController captionCtrl;
  final TextEditingController locationCtrl;
  final VideoPlayerController? videoController;
  final bool videoInitialized;

  const _AddPostPageBody({
    this.filePath,
    this.fileBytes,
    this.fileName,
    this.webUrl,
    required this.mediaType,
    required this.aspectRatio,
    required this.captionCtrl,
    required this.locationCtrl,
    this.videoController,
    required this.videoInitialized,
  });

  void _submit(BuildContext context) {
    context.read<PostCreationCubit>().submitPost(
          filePath: filePath,
          fileBytes: fileBytes,
          fileName: fileName,
          webUrl: webUrl,
          mediaType: mediaType,
          aspectRatio: aspectRatio,
          caption: captionCtrl.text,
          location: locationCtrl.text,
        );
  }

  Widget _buildPreviewWidget() {
    if (mediaType == 'video') {
      if (videoInitialized && videoController != null) {
        return VideoPlayer(videoController!);
      } else {
        return Container(
          color: AppColors.darkSurface,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }
    } else {
      if (fileBytes != null) {
        return Image.memory(fileBytes!, fit: BoxFit.cover);
      } else if (filePath != null && !kIsWeb) {
        return Image.file(File(filePath!), fit: BoxFit.cover);
      } else if (webUrl != null) {
        return Image.network(
          webUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppColors.darkSurface,
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.white30, size: 40),
            ),
          ),
        );
      }
      return Container(color: AppColors.darkSurface);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PostCreationCubit, PostCreationState>(
      listener: (context, state) {
        if (state is PostCreationSuccess) {
          // Return true so CameraPage knows to swipe back to home feed.
          Navigator.pop(context, true);
        }
        if (state is PostCreationFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is PostCreationLoading;

        return Scaffold(
          backgroundColor: AppColors.darkBackground,
          appBar: AppBar(
            backgroundColor: AppColors.darkBackground,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: isLoading ? null : () => Navigator.pop(context),
            ),
            title: const Text(
              'New Post',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: isLoading ? null : () => _submit(context),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Share',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Media preview
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: _buildPreviewWidget(),
                  ),
                ),
                const SizedBox(height: 20),

                // Caption
                _PostField(
                  controller: captionCtrl,
                  hint: 'Write a caption...',
                  icon: Icons.edit_outlined,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),

                // Location
                _PostField(
                  controller: locationCtrl,
                  hint: 'Add location',
                  icon: Icons.location_on_outlined,
                  maxLines: 1,
                ),
                const SizedBox(height: 32),

                // Share button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: isLoading
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                            ),
                      color: isLoading ? AppColors.darkSurface : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: isLoading ? null : () => _submit(context),
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            )
                          : const Text(
                              'Share Post',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PostField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;

  const _PostField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder, width: 0.5),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        minLines: 1,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textSubtleOnDark, size: 20),
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textSubtleOnDark),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
