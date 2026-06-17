import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/services/session_storage.dart';
import 'core/services/hive_storage.dart';
import 'core/services/notification_service.dart';
import 'core/services/settings_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_manager.dart';
import 'features/splash/view/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveStorage.init();
  await NotificationService.init();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_KEY']!,
  );

  // Keep the SharedPreferences hash in sync with Supabase's token lifecycle.
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final session = data.session;
    switch (data.event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
        if (session != null) SessionStorage.save(session.accessToken);
      case AuthChangeEvent.signedOut:
        SessionStorage.clear();
      default:
        break;
    }
  });

  // Load saved theme mode
  final isDark = await SettingsStorage.isDarkMode();
  ThemeManager.themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeModeNotifier,
      builder: (context, currentThemeMode, _) {
        return MaterialApp(
          title: 'Aura',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: currentThemeMode,
          home: const SplashPage(),
        );
      },
    );
  }
}
