import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../post/view/add_post_page.dart';

class CameraPage extends StatefulWidget {
  final PageController pageController;

  const CameraPage({super.key, required this.pageController});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _cameraInitializationFailed = false;
  String _cameraErrorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.pageController.addListener(_onPageScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.pageController.removeListener(_onPageScroll);
    _controller?.dispose();
    super.dispose();
  }

  // Initialize camera only when this page is becoming visible (page > 1.5).
  // Dispose when the user swipes back towards home.
  void _onPageScroll() {
    final page = widget.pageController.page ?? 1.0;
    if (page > 1.5 && !_isInitialized) {
      _initCamera();
    } else if (page <= 1.3 && _isInitialized) {
      _pauseCamera();
    }
  }

  void _pauseCamera() {
    _controller?.dispose();
    _controller = null;
    if (mounted) setState(() => _isInitialized = false);
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraInitializationFailed = true;
            _cameraErrorMessage = 'No cameras found on this device.';
          });
        }
        return;
      }
      await _startCamera(_cameraIndex);
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) {
        setState(() {
          _cameraInitializationFailed = true;
          _cameraErrorMessage = 'Could not access camera: $e';
        });
      }
    }
  }

  Future<void> _startCamera(int index) async {
    final old = _controller;
    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setFlashMode(_flashMode);
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _cameraInitializationFailed = false;
        });
      }
    } catch (e) {
      debugPrint('Camera start error: $e');
      if (mounted) {
        setState(() {
          _cameraInitializationFailed = true;
          _cameraErrorMessage = 'Failed to start camera: $e';
        });
      }
    }
    await old?.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _pauseCamera();
    } else if (state == AppLifecycleState.resumed) {
      final page = widget.pageController.page ?? 1.0;
      if (page > 1.5) _initCamera();
    }
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }
    setState(() => _isCapturing = true);
    try {
      final file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      await _openPostCreation(
        filePath: kIsWeb ? null : file.path,
        fileBytes: bytes,
        fileName: file.name,
        mediaType: 'image',
      );
    } catch (e) {
      debugPrint('Capture error: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.media,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final ext = file.extension?.toLowerCase();
    final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'].contains(ext);
    final mediaType = isVideo ? 'video' : 'image';

    if (!mounted) return;
    await _openPostCreation(
      filePath: file.path,
      fileBytes: file.bytes,
      fileName: file.name,
      mediaType: mediaType,
    );
  }

  Future<void> _openPostCreation({
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
    String? webUrl,
    required String mediaType,
  }) async {
    final posted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddPostPage(
          filePath: filePath,
          fileBytes: fileBytes,
          fileName: fileName,
          webUrl: webUrl,
          mediaType: mediaType,
        ),
      ),
    );
    if (posted == true && mounted) {
      widget.pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showAddMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
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
                leading: const Icon(Icons.photo_library_outlined, color: Colors.white),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.language_rounded, color: Colors.white),
                title: const Text('Add from Web URL', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showWebUrlDialog();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
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
                'Add from Web URL',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Paste a direct link to a picture or video:',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
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
                    _openPostCreation(
                      webUrl: url,
                      mediaType: selectedType,
                    );
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

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final next = switch (_flashMode) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      _ => FlashMode.off,
    };
    await _controller!.setFlashMode(next);
    setState(() => _flashMode = next);
  }

  void _flipCamera() {
    if (_cameras.length < 2) return;
    setState(() => _isInitialized = false);
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    _startCamera(_cameraIndex);
  }

  IconData get _flashIcon => switch (_flashMode) {
        FlashMode.auto => Icons.flash_auto_rounded,
        FlashMode.always => Icons.flash_on_rounded,
        _ => Icons.flash_off_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Live preview ────────────────────────────────────────────────────
          if (_isInitialized && _controller != null)
            CameraPreview(_controller!)
          else if (_cameraInitializationFailed)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.videocam_off_rounded,
                      color: Colors.white30,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _cameraErrorMessage,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _showAddMediaOptions,
                      icon: const Icon(Icons.add_photo_alternate_rounded),
                      label: const Text('Add Photo/Video'),
                    ),
                  ],
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),

          // ── Top bar ─────────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CamIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => widget.pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                  _CamIconButton(
                    icon: _flashIcon,
                    onTap: _toggleFlash,
                  ),
                ],
              ),
            ),
          ),

          // ── NEW POST label ───────────────────────────────────────────────────
          Positioned(
            bottom: 148,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'NEW POST',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // ── Bottom controls ──────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 28),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Gallery
                    GestureDetector(
                      onTap: _showAddMediaOptions,
                      child: _ControlBox(
                        child: const Icon(
                          Icons.photo_library_outlined,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),

                    // Shutter button
                    GestureDetector(
                      onTap: _isCapturing ? null : _capture,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: _isCapturing ? 68 : 76,
                        height: _isCapturing ? 68 : 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),

                    // Flip camera
                    GestureDetector(
                      onTap: _flipCamera,
                      child: _ControlBox(
                        isCircle: true,
                        child: const Icon(
                          Icons.flip_camera_ios_outlined,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _CamIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CamIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.45),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _ControlBox extends StatelessWidget {
  final Widget child;
  final bool isCircle;

  const _ControlBox({required this.child, this.isCircle = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: child,
    );
  }
}
