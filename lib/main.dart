import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/database/molly_local_database.dart';
import 'core/services/antigravity_oauth_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/main_shell_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Konfigurasi Edge-to-Edge System Bar (Apple HIG & Modern Android 14+ look)
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

  // Inisialisasi Local Storage, Antigravity OAuth & On-Device SQLite Database Mandiri
  await LocalStorageService.instance.init();
  await AntigravityOAuthService.instance.init();
  await MollyLocalDatabase.instance.database;

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
