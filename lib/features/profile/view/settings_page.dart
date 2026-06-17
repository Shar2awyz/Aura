import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/core/services/settings_storage.dart';
import 'package:untitled/core/services/saved_accounts_storage.dart';
import 'package:untitled/core/services/session_storage.dart';
import 'package:untitled/core/theme/theme_manager.dart';
import 'package:untitled/core/theme/app_colors.dart';
import 'package:untitled/features/auth/log_in/view/LoginPage.dart';
import 'package:untitled/features/shell/view/shell_page.dart';
import '../viewmodel/profile_cubit.dart';
import '../viewmodel/profile_state.dart';
import 'customer_service_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDark = true;
  bool _notificationsStopped = false;
  List<Map<String, dynamic>> _savedAccounts = [];
  bool _isSwitching = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final dark = await SettingsStorage.isDarkMode();
    final stopped = await SettingsStorage.areNotificationsStopped();
    final accounts = SavedAccountsStorage.getAccounts();
    if (mounted) {
      setState(() {
        _isDark = dark;
        _notificationsStopped = stopped;
        _savedAccounts = accounts;
      });
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    await SettingsStorage.setDarkMode(value);
    ThemeManager.toggleTheme(value);
    setState(() {
      _isDark = value;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    await SettingsStorage.setNotificationsStopped(value);
    setState(() {
      _notificationsStopped = value;
    });
  }

  Future<void> _switchAccount(Map<String, dynamic> account) async {
    if (_isSwitching) return;
    setState(() {
      _isSwitching = true;
    });

    try {
      // 1. Sign out of current session
      await Supabase.instance.client.auth.signOut();
      await SessionStorage.clear();

      // 2. Sign in with saved credentials
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: account['email'],
        password: account['password'],
      );

      if (response.session != null) {
        // 3. Save session token
        await SessionStorage.save(response.session!.accessToken);
        
        // 4. Update last used timestamp in local storage
        await SavedAccountsStorage.saveAccount(
          userId: account['id'],
          email: account['email'],
          password: account['password'],
          username: account['username'],
          avatarUrl: account['avatar_url'],
        );

        // 5. Navigate to ShellPage and clear stack
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ShellPage()),
            (_) => false,
          );
        }
      } else {
        throw Exception("Session is null");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch account: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
        // If login failed, remove this account since credentials might be invalid, or let them log in again
        setState(() {
          _isSwitching = false;
        });
      }
    }
  }

  Future<void> _deleteSavedAccount(String userId) async {
    await SavedAccountsStorage.removeAccount(userId);
    _loadSettings();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account removed from device'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      await SessionStorage.clear();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log out: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _showAddAccountSheet() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isObscured = true;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final bottomPadding = MediaQuery.of(sheetContext).viewInsets.bottom;
            final isAppDark = Theme.of(sheetContext).brightness == Brightness.dark;

            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: 24 + bottomPadding,
              ),
              decoration: BoxDecoration(
                color: isAppDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border.all(
                  color: isAppDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isAppDark ? AppColors.darkBorder : AppColors.lightBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Add Another Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isAppDark ? Colors.white : AppColors.textOnLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Email
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: isAppDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.primary),
                      labelText: 'EMAIL ADDRESS',
                      labelStyle: const TextStyle(fontSize: 12, color: AppColors.primary, letterSpacing: 1),
                      hintText: 'name@domain.com',
                      hintStyle: TextStyle(color: isAppDark ? Colors.white54 : Colors.black45),
                      filled: true,
                      fillColor: isAppDark ? AppColors.darkBackground : Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: isAppDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Password
                  TextField(
                    controller: passwordController,
                    obscureText: isObscured,
                    style: TextStyle(color: isAppDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.primary,
                        ),
                        onPressed: () => setSheetState(() => isObscured = !isObscured),
                      ),
                      labelText: 'PASSWORD',
                      labelStyle: const TextStyle(fontSize: 12, color: AppColors.primary, letterSpacing: 1),
                      hintText: '••••••••',
                      hintStyle: TextStyle(color: isAppDark ? Colors.white54 : Colors.black45),
                      filled: true,
                      fillColor: isAppDark ? AppColors.darkBackground : Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: isAppDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Submit button
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final email = emailController.text.trim();
                            final password = passwordController.text.trim();
                            if (email.isEmpty || password.isEmpty) return;

                            setSheetState(() => isSubmitting = true);
                            try {
                              // Perform sign in
                              final response = await Supabase.instance.client.auth.signInWithPassword(
                                email: email,
                                password: password,
                              );
                              if (response.session != null) {
                                final user = response.session!.user;
                                // Fetch profile details
                                final profileData = await Supabase.instance.client
                                    .from('profiles')
                                    .select()
                                    .eq('id', user.id)
                                    .maybeSingle();

                                if (profileData != null) {
                                  await SavedAccountsStorage.saveAccount(
                                    userId: user.id,
                                    email: email,
                                    password: password,
                                    username: profileData['username'] as String? ?? 'user',
                                    avatarUrl: profileData['avatar_url'] as String? ?? '',
                                  );
                                }
                                await SessionStorage.save(response.session!.accessToken);
                                
                                if (mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ShellPage()),
                                    (_) => false,
                                  );
                                }
                              }
                            } catch (e) {
                              setSheetState(() => isSubmitting = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('Verification failed: ${e.toString()}'),
                                    backgroundColor: Colors.red.shade700,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Sign In & Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isThemeDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

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
        title: Text(
          'Settings',
          style: TextStyle(
            color: isThemeDark ? Colors.white : AppColors.textOnLight,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── SECTION: PREFERENCES ─────────────────────────────────────
                _buildSectionHeader('APP PREFERENCES', isThemeDark),
                _buildCard(
                  isThemeDark,
                  children: [
                    _buildSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Mode',
                      subtitle: 'Switch application aesthetics',
                      value: _isDark,
                      onChanged: _toggleDarkMode,
                      isThemeDark: isThemeDark,
                    ),
                    _buildDivider(isThemeDark),
                    _buildSwitchTile(
                      icon: Icons.notifications_off_outlined,
                      title: 'Stop Notifications',
                      subtitle: 'Pause all push & local alerts',
                      value: _notificationsStopped,
                      onChanged: _toggleNotifications,
                      isThemeDark: isThemeDark,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── SECTION: PRIVACY ──────────────────────────────────────────
                _buildSectionHeader('PRIVACY', isThemeDark),
                BlocBuilder<ProfileCubit, ProfileState>(
                  builder: (context, state) {
                    bool isPrivate = false;
                    bool isUpdating = false;

                    if (state is ProfileSuccess) {
                      isPrivate = state.profile.isPrivate;
                    } else if (state is ProfileLoading) {
                      isUpdating = true;
                    }

                    return _buildCard(
                      isThemeDark,
                      children: [
                        _buildSwitchTile(
                          icon: Icons.lock_outline_rounded,
                          title: 'Private Account',
                          subtitle: 'Only approved followers can see posts',
                          value: isPrivate,
                          isLoading: isUpdating,
                          onChanged: (val) {
                            context.read<ProfileCubit>().toggleProfilePrivacy(val);
                          },
                          isThemeDark: isThemeDark,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ── SECTION: SUPPORT ──────────────────────────────────────────
                _buildSectionHeader('SUPPORT', isThemeDark),
                _buildCard(
                  isThemeDark,
                  children: [
                    _buildNavigationTile(
                      icon: Icons.support_agent_rounded,
                      title: 'Customer Service',
                      subtitle: 'Interactive support chatbot prototype',
                      isThemeDark: isThemeDark,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CustomerServicePage()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── SECTION: ACCOUNT SWITCHER ─────────────────────────────────
                _buildSectionHeader('ACCOUNTS', isThemeDark),
                _buildCard(
                  isThemeDark,
                  children: [
                    ..._savedAccounts.map((account) {
                      final isActive = account['id'] == currentUserId;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: isThemeDark ? AppColors.darkBackground : AppColors.lightBackground,
                              backgroundImage: (account['avatar_url'] as String).isNotEmpty
                                  ? NetworkImage(account['avatar_url'])
                                  : null,
                              child: (account['avatar_url'] as String).isEmpty
                                  ? const Icon(Icons.person, color: AppColors.primary, size: 20)
                                  : null,
                            ),
                            title: Text(
                              account['username'] ?? 'User',
                              style: TextStyle(
                                color: isThemeDark ? Colors.white : AppColors.textOnLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              account['email'] ?? '',
                              style: TextStyle(
                                color: isThemeDark ? AppColors.textSubtleOnDark : AppColors.textSubtleOnLight,
                                fontSize: 12,
                              ),
                            ),
                            trailing: isActive
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Active',
                                      style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 22),
                                        onPressed: () => _switchAccount(account),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 20),
                                        onPressed: () => _deleteSavedAccount(account['id']),
                                      ),
                                    ],
                                  ),
                          ),
                          _buildDivider(isThemeDark),
                        ],
                      );
                    }),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: const CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                      title: Text(
                        'Add Account',
                        style: TextStyle(
                          color: isThemeDark ? Colors.white : AppColors.textOnLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        'Log in to another Aura account',
                        style: TextStyle(
                          color: isThemeDark ? AppColors.textSubtleOnDark : AppColors.textSubtleOnLight,
                          fontSize: 12,
                        ),
                      ),
                      onTap: _showAddAccountSheet,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── LOGOUT BUTTON ─────────────────────────────────────────────
                ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Log Out Session', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900.withValues(alpha: 0.2),
                    foregroundColor: Colors.red.shade300,
                    side: BorderSide(color: Colors.red.shade800.withValues(alpha: 0.4), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isSwitching)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Switching Account...',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isThemeDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
          color: isThemeDark ? AppColors.textOnDark.withValues(alpha: 0.5) : AppColors.textSubtleOnLight,
        ),
      ),
    );
  }

  Widget _buildCard(bool isThemeDark, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isThemeDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isThemeDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }

  Widget _buildDivider(bool isThemeDark) {
    return Divider(
      color: isThemeDark ? AppColors.darkBorder : AppColors.lightBorder,
      height: 1,
      thickness: 1,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isThemeDark,
    bool isLoading = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isThemeDark ? AppColors.darkBackground : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isThemeDark ? Colors.white : AppColors.textOnLight,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isThemeDark ? AppColors.textSubtleOnDark : AppColors.textSubtleOnLight,
          fontSize: 12,
        ),
      ),
      trailing: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            )
          : Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.primary,
            ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isThemeDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isThemeDark ? AppColors.darkBackground : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isThemeDark ? Colors.white : AppColors.textOnLight,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isThemeDark ? AppColors.textSubtleOnDark : AppColors.textSubtleOnLight,
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isThemeDark ? AppColors.textSubtleOnDark : AppColors.textSubtleOnLight,
      ),
      onTap: onTap,
    );
  }
}
