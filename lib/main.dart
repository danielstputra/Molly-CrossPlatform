import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/database/molly_local_database.dart';
import 'core/services/antigravity_oauth_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/main_shell_screen.dart';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/database/molly_local_database.dart';
import 'core/services/antigravity_oauth_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/main_shell_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Error Interceptors untuk mencegah aplikasi Crash/Force Close pada Android 14/15/16
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[Molly Error] ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[Molly Async Error] $error\n$stack');
    return true; // Mencegah OS mematikan proses jika terjadi async unhandled error
  };

  // Konfigurasi Edge-to-Edge System Bar (Apple HIG & Modern Android Look)
  try {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  } catch (e) {
    debugPrint('SystemUIOverlayStyle error: $e');
  }

  // Inisialisasi Service Lokal dengan Perlindungan Try-Catch (Fail-Safe Startup)
  try {
    await LocalStorageService.instance.init();
  } catch (e) {
    debugPrint('LocalStorageService init error: $e');
  }

  try {
    await AntigravityOAuthService.instance.init();
  } catch (e) {
    debugPrint('AntigravityOAuthService init error: $e');
  }

  try {
    await MollyLocalDatabase.instance.database;
  } catch (e) {
    debugPrint('MollyLocalDatabase init error: $e');
  }

  runApp(const MollyApp());
}

class MollyApp extends StatelessWidget {
  const MollyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Molly AI Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const MainShellScreen(),
    );
  }
}
