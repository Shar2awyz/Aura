import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/components/custom_bottom_nav_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../camera/view/camera_page.dart';
import '../../home/view/home_page.dart';
import '../../messages/view/messages_page.dart';
import '../../messages/viewmodel/messages_cubit.dart';
import '../../notifications/viewmodel/notifications_cubit.dart';
import '../../profile/view/profile_page.dart';
import '../../reels/view/reels_page.dart';
import '../../search/view/search_page.dart';

/// Root shell.
///
/// PageView layout:
///   page 0 — MessagesPage  (swipe right from Home)
///   page 1 — HomePage      (initial / center)
///   page 2 — CameraPage    (swipe left from Home)
///
/// Search and Profile tabs are shown as full-screen overlays via IndexedStack.
class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  late final PageController _pageController;

  // Bottom-nav index: 0=Home 1=Search 2=Create 3=Reels 4=Profile
  int _navIndex = 0;

  bool get _overlayActive => _navIndex == 1 || _navIndex == 3 || _navIndex == 4;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
    _pageController.addListener(_syncNavFromPage);
  }

  @override
  void dispose() {
    _pageController
      ..removeListener(_syncNavFromPage)
      ..dispose();
    super.dispose();
  }

  // Keep nav highlight in sync while the user drags between pages.
  void _syncNavFromPage() {
    if (_overlayActive) return;
    final page = _pageController.page ?? 1.0;
    final int target = page > 1.5 ? 2 : 0; // Create or Home (messages swipe keeps Home)
    if (target != _navIndex) setState(() => _navIndex = target);
  }

  void _onNavTap(int index) {
    setState(() => _navIndex = index);
    switch (index) {
      case 0: // Home
        _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      case 2: // Create — open camera
        _pageController.animateToPage(
          2,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      default: // Search (1), Reels (3), Profile (4) are overlays — no page animation
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => MessagesCubit()..loadChats()),
        BlocProvider(create: (_) => NotificationsCubit()..loadNotifications()),
      ],
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Stack(
          children: [
            // ── PageView: Messages | Home | Camera ─────────────────────────────
            Positioned.fill(
              child: PageView(
                controller: _pageController,
                physics: _overlayActive
                    ? const NeverScrollableScrollPhysics()
                    : const ClampingScrollPhysics(),
                children: [
                  MessagesPage(pageController: _pageController),
                  HomePage(pageController: _pageController),
                  CameraPage(pageController: _pageController),
                ],
              ),
            ),
  
            // ── Overlay tabs: Search / Reels / Profile ─────────────────────────
            if (_overlayActive)
              Positioned.fill(
                child: IndexedStack(
                  index: _navIndex == 1 ? 0 : (_navIndex == 3 ? 1 : 2),
                  children: const [
                    _SearchPage(),
                    ReelsPage(),
                    _ProfilePage(),
                  ],
                ),
              ),
          ],
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _navIndex,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}

// ── Placeholder overlay pages ─────────────────────────────────────────────────

class _SearchPage extends StatelessWidget {
  const _SearchPage();

  @override
  Widget build(BuildContext context) => const SearchPage();
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) => const ProfilePage();
}
