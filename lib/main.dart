import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/database/molly_local_database.dart';
import 'core/services/antigravity_oauth_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/molly_background_service.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/main_shell_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi Firebase & Google Crashlytics
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Otomatis aktifkan pengumpulan crash
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    await FirebaseCrashlytics.instance.setCustomKey('app_name', 'Molly AI Studio');
    await FirebaseCrashlytics.instance.setCustomKey('app_version', '2.6.0');

    // Meneruskan semua fatal error dari Flutter framework ke Crashlytics
    FlutterError.onError = (details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      FlutterError.presentError(details);
    };

    // Meneruskan semua async error tak tertangani ke Crashlytics tanpa mematikan UI
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint('[Firebase Crashlytics Error] Inisialisasi gagal: $e');
    // Fallback error handler jika Firebase tidak aktif
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('[Async Error] $error\n$stack');
      return true;
    };
  }

  // 2. Konfigurasi Edge-to-Edge System Bar (Apple HIG & Modern Android Look)
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

  // 3. Inisialisasi Service Lokal dengan Perlindungan Try-Catch (Fail-Safe Startup)
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

  try {
    await MollyBackgroundService.instance.init();
  } catch (e) {
    debugPrint('MollyBackgroundService init error: $e');
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
