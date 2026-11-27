import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/database/molly_local_database.dart';
import '../../core/services/antigravity_oauth_service.dart';
import '../../core/services/direct_provider_service.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/services/molly_background_service.dart';
import '../../core/services/app_update_service.dart';
import '../../core/widgets/app_update_dialog.dart';
import '../../core/widgets/changelog_modal.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_decorations.dart';
import '../../core/widgets/glass_app_bar.dart';
import '../../core/widgets/molly_toast.dart';
import '../../core/widgets/molly_text_field.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = LocalStorageService.instance;
  final _oauth = AntigravityOAuthService.instance;
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();

  String _activeProvider = 'Gemini Antigravity';
  bool _obscureApiKey = true;
  bool _isLoadingDb = true;
  bool _isOAuthLoading = false;

  bool _bgKeepAlive = true;
  bool _bgNotifications = true;
  bool _notifyConfirmation = true;
  bool _notifySuccess = true;
  bool _notifyFailure = true;
  bool _isBatteryOptimized = false;
  bool _autoCheckUpdates = true;
  bool _isCheckingUpdates = false;
  GitHubRelease? _latestRelease;

  Map<String, int> _dbStats = {
    'sessions': 0,
    'messages': 0,
    'agents': 0,
    'knowledge_datasets': 0,
    'knowledge_chunks': 0,
    'workspace_files': 0,
    'background_jobs': 0,
  };

  final List<String> _providers = [
    'Gemini Antigravity',
    'OpenAI',
    'Anthropic',
    'Gemini',
    'Groq',
    'Ollama',
  ];

  final List<String> _antigravityModels = [
    'gemini-3.8-flash-medium',
    'gemini-3.8-flash-low',
    'gemini-3.8-flash-high',
    'gemini-3.8-pro',
    'gemini-2.5-pro',
    'claude-sonnet-4-6-thinking',
    'claude-opus-4-6-thinking',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _refreshDbStats();
  }

  Future<void> _loadSettings() async {
    await _storage.init();
    await _oauth.init();
    setState(() {
      _activeProvider = _storage.getActiveProvider();
      _apiKeyController.text = _storage.getApiKey(_activeProvider);
      _modelController.text = _storage.getActiveModel();
      _bgKeepAlive = _storage.getBackgroundKeepAlive();
      _bgNotifications = _storage.getBackgroundNotifications();
      _notifyConfirmation = _storage.getNotifyConfirmation();
      _notifySuccess = _storage.getNotifySuccess();
      _notifyFailure = _storage.getNotifyFailure();
      _autoCheckUpdates = _storage.getAutoCheckUpdates();
    });

    MollyBackgroundService.instance.isBatteryOptimizationIgnored().then((val) {
      if (mounted) setState(() => _isBatteryOptimized = val);
    });
  }

  Future<void> _refreshDbStats() async {
    setState(() => _isLoadingDb = true);
    try {
      final db = await MollyLocalDatabase.instance.database;
      final sessionsCount = (await db.rawQuery('SELECT COUNT(*) as c FROM sessions')).first['c'] as int? ?? 0;
      final messagesCount = (await db.rawQuery('SELECT COUNT(*) as c FROM messages')).first['c'] as int? ?? 0;
      final agentsCount = (await db.rawQuery('SELECT COUNT(*) as c FROM agents')).first['c'] as int? ?? 0;
      final datasetsCount = (await db.rawQuery('SELECT COUNT(*) as c FROM knowledge_datasets')).first['c'] as int? ?? 0;
      final chunksCount = (await db.rawQuery('SELECT COUNT(*) as c FROM knowledge_chunks')).first['c'] as int? ?? 0;
      final filesCount = (await db.rawQuery('SELECT COUNT(*) as c FROM workspace_files')).first['c'] as int? ?? 0;
      final jobsCount = (await db.rawQuery('SELECT COUNT(*) as c FROM background_jobs')).first['c'] as int? ?? 0;

      if (mounted) {
        setState(() {
          _dbStats = {
            'sessions': sessionsCount,
            'messages': messagesCount,
            'agents': agentsCount,
            'knowledge_datasets': datasetsCount,
            'knowledge_chunks': chunksCount,
            'workspace_files': filesCount,
            'background_jobs': jobsCount,
          };
          _isLoadingDb = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingDb = false);
    }
  }

  void _onSelectProvider(String provider) async {
    HapticFeedback.selectionClick();
    await _storage.setActiveProvider(provider);
    final key = _storage.getApiKey(provider);

    String defaultModel = 'gemini-3.8-flash-medium';
    if (provider == 'OpenAI') defaultModel = 'gpt-4o';
    if (provider == 'Anthropic') defaultModel = 'claude-3-5-sonnet-20241022';
    if (provider == 'Gemini') defaultModel = 'gemini-1.5-flash';
    if (provider == 'Groq') defaultModel = 'llama-3.3-70b-versatile';
    if (provider == 'Ollama') defaultModel = 'llama3';

    await _storage.setActiveModel(defaultModel);

    setState(() {
      _activeProvider = provider;
      _apiKeyController.text = key;
      _modelController.text = defaultModel;
    });
  }

  Future<void> _startGoogleOAuth() async {
    HapticFeedback.heavyImpact();
    setState(() => _isOAuthLoading = true);

    bool sheetOpen = false;
    try {
      final profile = await _oauth.startGoogleOAuth(
        onUrlReady: (url) {
          if (mounted) {
            sheetOpen = true;
            _showOAuthLoginSheet(url);
          }
        },
      );

      if (sheetOpen && mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      await _storage.setActiveProvider('Gemini Antigravity');
      await _storage.setActiveModel('gemini-3.8-flash-medium');

      setState(() {
        _activeProvider = 'Gemini Antigravity';
        _modelController.text = 'gemini-3.8-flash-medium';
        _isOAuthLoading = false;
      });

      if (mounted) {
        MollyToast.showSuccess(
          context,
          'Berhasil terhubung ke akun ${profile.email}! Provider Gemini Antigravity aktif.',
          title: 'Google OAuth Terhubung',
        );
      }
    } catch (e) {
      if (sheetOpen && mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      setState(() => _isOAuthLoading = false);
      if (mounted) {
        MollyToast.showError(
          context,
          'Otentikasi Google OAuth gagal: $e',
          title: 'Gagal Otentikasi',
        );
      }
    }
  }

  void _showOAuthLoginSheet(Uri authUrl) {
    final manualCodeCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1117),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 0.8),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold.withOpacity(0.15),
                        border: Border.all(color: AppColors.gold, width: 1.5),
                      ),
                      child: const Center(
                        child: Icon(CupertinoIcons.lock_shield_fill, color: AppColors.gold, size: 26),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Otentikasi Google OAuth Antigravity',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pilih akun Google Anda untuk mengizinkan akses model Gemini 3.8 & Antigravity.',
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Tombol Aksi Buka Browser Langsung
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        icon: const Icon(CupertinoIcons.arrow_up_right_square_fill, size: 18, color: Colors.black),
                        label: const Text(
                          'Buka Browser Login Google Sekarang',
                          style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          try {
                            final ok = await launchUrl(authUrl, mode: LaunchMode.externalApplication);
                            if (!ok) {
                              final inApp = await launchUrl(authUrl, mode: LaunchMode.inAppBrowserView);
                              if (!inApp) await launchUrl(authUrl, mode: LaunchMode.platformDefault);
                            }
                          } catch (_) {
                            await launchUrl(authUrl, mode: LaunchMode.inAppBrowserView);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Tombol Salin Tautan
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: OutlinedButton.icon(
                        icon: const Icon(CupertinoIcons.doc_on_clipboard, size: 15, color: Colors.white70),
                        label: const Text('Salin Tautan Login Google', style: TextStyle(color: Colors.white, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.glassBorder),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: authUrl.toString()));
                          MollyToast.showSuccess(context, 'Tautan login berhasil disalin!');
                        },
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: AppColors.glassBorder, height: 1),
                    const SizedBox(height: 14),

                    // Pilihan Verifikasi Kode Manual
                    MollyTextField(
                      controller: manualCodeCtrl,
                      labelText: 'Kode OAuth / URL Callback dari Browser',
                      hintText: 'Tempel URL atau code=... dari address bar',
                      suffixIcon: IconButton(
                        icon: const Icon(CupertinoIcons.doc_on_clipboard_fill, color: AppColors.gold, size: 18),
                        tooltip: 'Tempel dari Clipboard',
                        onPressed: () async {
                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                          if (data?.text != null && data!.text!.isNotEmpty) {
                            manualCodeCtrl.text = data.text!;
                            _oauth.submitManualCode(data.text!);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () {
                          if (manualCodeCtrl.text.trim().isNotEmpty) {
                            _oauth.submitManualCode(manualCodeCtrl.text.trim());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceElevated,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: const BorderSide(color: AppColors.gold, width: 0.8),
                        ),
                        child: const Text('Verifikasi Kode Manual', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),

                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () {
                        _oauth.cancelOAuth();
                        Navigator.pop(ctx);
                        setState(() => _isOAuthLoading = false);
                      },
                      child: const Text('Batalkan & Tutup', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _refreshGoogleToken() async {
    HapticFeedback.selectionClick();
    setState(() => _isOAuthLoading = true);
    try {
      await _oauth.refreshAccessToken();
      setState(() => _isOAuthLoading = false);
      if (mounted) {
        MollyToast.showSuccess(
          context,
          'Access Token Google Antigravity berhasil diperbarui!',
          title: 'Token Diperbarui',
        );
      }
    } catch (e) {
      setState(() => _isOAuthLoading = false);
      if (mounted) {
        MollyToast.showError(
          context,
          'Gagal memperbarui token: $e',
          title: 'Pembaruan Gagal',
        );
      }
    }
  }

  Future<void> _signOutGoogle() async {
    HapticFeedback.mediumImpact();
    await _oauth.signOut();
    setState(() {});
    if (mounted) {
      MollyToast.showInfo(
        context,
        'Akun Google Antigravity telah diputus.',
        title: 'Akun Diputus',
      );
    }
  }

  bool _isFetchingLiveModels = false;

  Future<void> _fetchLiveModelsFromProvider() async {
    HapticFeedback.lightImpact();
    setState(() => _isFetchingLiveModels = true);

    try {
      final models = await DirectProviderService.instance.fetchLiveModels(
        _activeProvider,
        apiKey: _apiKeyController.text.trim(),
      );

      setState(() => _isFetchingLiveModels = false);

      if (!mounted) return;

      if (models.isEmpty) {
        MollyToast.showWarning(
          context,
          'Tidak ada model ditemukan untuk $_activeProvider. Pastikan API Key valid atau server menyala.',
          title: 'Model Kosong',
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 0.8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'MODEL REAL RESMI: $_activeProvider (${models.length})',
                      style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.greenAccent, size: 16),
                ],
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: models.length,
                  separatorBuilder: (_, __) => const Divider(color: AppColors.glassBorder, height: 1),
                  itemBuilder: (ctx, index) {
                    final m = models[index];
                    final isCurrent = _modelController.text == m;

                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isCurrent ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
                        color: isCurrent ? AppColors.gold : AppColors.textTertiary,
                        size: 16,
                      ),
                      title: Text(
                        m,
                        style: TextStyle(
                          color: isCurrent ? Colors.white : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          fontFamily: 'monospace',
                        ),
                      ),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _modelController.text = m;
                        });
                        Navigator.pop(ctx);
                        _saveDirectSettings();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      setState(() => _isFetchingLiveModels = false);
      if (mounted) {
        MollyToast.showError(
          context,
          'Gagal menarik model: $e',
          title: 'Gagal Menarik Model',
        );
      }
    }
  }

  void _saveDirectSettings() async {
    HapticFeedback.mediumImpact();
    await _storage.setApiKey(_activeProvider, _apiKeyController.text.trim());
    await _storage.setActiveModel(_modelController.text.trim());
    if (mounted) {
      MollyToast.showSuccess(
        context,
        'Konfigurasi provider $_activeProvider berhasil disimpan!',
        title: 'Pengaturan Disimpan',
      );
    }
  }

  Future<void> _vacuumDatabase() async {
    HapticFeedback.heavyImpact();
    try {
      final db = await MollyLocalDatabase.instance.database;
      await db.execute('VACUUM');
      await _refreshDbStats();
      if (mounted) {
        MollyToast.showSuccess(
          context,
          'SQLite VACUUM selesai! Basis data lokal berhasil dioptimasi.',
          title: 'Database Dioptimasi',
        );
      }
    } catch (e) {
      if (mounted) {
        MollyToast.showError(
          context,
          'Gagal optimasi database: $e',
          title: 'Optimasi Gagal',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(
        title: 'Pengaturan Engine & Sistem',
        showBackButton: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 125),
        children: [
          _buildStandaloneEngineStatusCard(),
          const SizedBox(height: 18),
          _buildBackgroundTaskCard(),
          const SizedBox(height: 18),
          _buildAppUpdateCard(),
          const SizedBox(height: 18),
          _buildGoogleOAuthCard(),
          const SizedBox(height: 18),
          _buildLocalDatabaseCard(),
          const SizedBox(height: 18),
          _buildDirectProviderCard(),
          const SizedBox(height: 18),
          _buildCrashlyticsCard(),
          const SizedBox(height: 18),
          _buildAboutCard(),
        ],
      ),
    );
  }

  Widget _buildBackgroundTaskCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecorations.frostedCard(
        blur: 20,
        borderColor: AppColors.info.withOpacity(0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Background Keep-Alive & Notifikasi',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Menjaga task AI tetap berjalan saat HP diminimize',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _bgKeepAlive ? const Color(0x2210B981) : const Color(0x226B7280),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _bgKeepAlive ? AppColors.success : AppColors.borderGlass,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  _bgKeepAlive ? 'AKTIF' : 'NONAKTIF',
                  style: TextStyle(
                    color: _bgKeepAlive ? AppColors.success : AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Penjelasan fitur
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Saat diaktifkan, Molly mengakuisisi CPU WakeLock & Notifikasi sistem HP sehingga OS tidak menghentikan proses penalaran agen AI saat aplikasi disembunyikan atau layar terkunci.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Switch: Izinkan Background Keep-Alive
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.gold,
            title: const Text(
              'Izinkan Eksekusi Latar Belakang (Keep-Alive)',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'CPU HP tetap aktif mengeksekusi LLM/Tool saat aplikasi diminimize',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
            value: _bgKeepAlive,
            onChanged: (val) async {
              HapticFeedback.selectionClick();
              await _storage.setBackgroundKeepAlive(val);
              setState(() => _bgKeepAlive = val);
            },
          ),
          const Divider(color: Colors.white12, height: 20),

          // Switch: Notifikasi Status Task HP
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.gold,
            title: const Text(
              'Notifikasi Status Task HP',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Tampilkan notifikasi di Notification Bar & Heads-up saat task berjalan/selesai',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
            value: _bgNotifications,
            onChanged: (val) async {
              HapticFeedback.selectionClick();
              await _storage.setBackgroundNotifications(val);
              setState(() => _bgNotifications = val);
            },
          ),

          if (_bgNotifications) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.info.withOpacity(0.15)),
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.warning,
                    checkColor: Colors.black,
                    title: const Text(
                      '⚠️ Notifikasi Konfirmasi Diperlukan',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Alert prioritas tinggi jika agen membutuhkan persetujuan tindakan',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                    ),
                    value: _notifyConfirmation,
                    onChanged: (val) async {
                      if (val == null) return;
                      await _storage.setNotifyConfirmation(val);
                      setState(() => _notifyConfirmation = val);
                    },
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.success,
                    checkColor: Colors.black,
                    title: const Text(
                      '✅ Notifikasi Task Sukses',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Ringkasan hasil ketika agen menyelesaikan seluruh tahapan tugas',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                    ),
                    value: _notifySuccess,
                    onChanged: (val) async {
                      if (val == null) return;
                      await _storage.setNotifySuccess(val);
                      setState(() => _notifySuccess = val);
                    },
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.error,
                    checkColor: Colors.white,
                    title: const Text(
                      '❌ Notifikasi Task Gagal',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Pemberitahuan darurat bila terjadi kendala atau kegagalan engine',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                    ),
                    value: _notifyFailure,
                    onChanged: (val) async {
                      if (val == null) return;
                      await _storage.setNotifyFailure(val);
                      setState(() => _notifyFailure = val);
                    },
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Android Battery Optimization exemption
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Optimasi Baterai HP (Doze Mode)',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _isBatteryOptimized ? const Color(0x2210B981) : const Color(0x22F59E0B),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _isBatteryOptimized ? 'Bebas Hambatan' : 'Dibatasi Sistem',
                        style: TextStyle(
                          color: _isBatteryOptimized ? AppColors.success : AppColors.gold,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Agar sistem operasi Android tidak menghentikan agen AI yang sedang bekerja di latar belakang, izinkan Molly untuk dikecualikan dari pembatasan baterai.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.08),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      await MollyBackgroundService.instance.requestBatteryOptimizationExemption();
                      final updated = await MollyBackgroundService.instance.isBatteryOptimizationIgnored();
                      if (mounted) setState(() => _isBatteryOptimized = updated);
                    },
                    icon: const Icon(Icons.battery_charging_full_rounded, size: 16, color: AppColors.info),
                    label: const Text('Buka Pengaturan Optimasi Baterai HP', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Uji Notifikasi Langsung
          const Text(
            'Uji Coba Notifikasi Sistem:',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    side: BorderSide(color: AppColors.warning.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await MollyBackgroundService.instance.notifyConfirmationRequired(
                      agentName: 'Molly Executive',
                      actionDescription: 'Tindakan eksekusi memerlukan otorisasi pengguna.',
                    );
                    if (mounted) MollyToast.showInfo(context, 'Notifikasi konfirmasi dikirim ke notification bar HP.');
                  },
                  child: const Text('⚠️ Konfirmasi', style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: BorderSide(color: AppColors.success.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await MollyBackgroundService.instance.notifyTaskSuccess(
                      agentName: 'Molly Executive',
                      summary: 'Pengerjaan 100% tuntas: Analisis dan kode telah selesai.',
                    );
                    if (mounted) MollyToast.showSuccess(context, 'Notifikasi sukses dikirim ke notification bar HP.');
                  },
                  child: const Text('✅ Sukses', style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await MollyBackgroundService.instance.notifyTaskFailed(
                      agentName: 'Molly Executive',
                      errorMessage: 'Terjadi timeout saat menunggu respons engine lokal.',
                    );
                    if (mounted) MollyToast.showError(context, 'Notifikasi gagal dikirim ke notification bar HP.');
                  },
                  child: const Text('❌ Gagal', style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppUpdateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecorations.frostedCard(
        blur: 20,
        borderColor: AppColors.gold.withOpacity(0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.system_update_rounded, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pembaruan Aplikasi & Changelog',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sinkronisasi rilis resmi & unduh update dari GitHub',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x22EAB308),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.gold, width: 0.8),
                ),
                child: Text(
                  _latestRelease != null && _latestRelease!.tagName != AppUpdateService.currentTag
                      ? 'UPDATE TERSEDIA'
                      : 'v${AppUpdateService.currentVersion}',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Detail versi saat ini
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Versi Terpasang:',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    Text(
                      AppUpdateService.currentTag,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Status Pembaruan:',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    Row(
                      children: [
                        Icon(
                          _isCheckingUpdates
                              ? CupertinoIcons.arrow_clockwise
                              : (_latestRelease != null && _latestRelease!.tagName != AppUpdateService.currentTag
                                  ? Icons.downloading_rounded
                                  : Icons.check_circle_rounded),
                          size: 13,
                          color: _isCheckingUpdates
                              ? AppColors.gold
                              : (_latestRelease != null && _latestRelease!.tagName != AppUpdateService.currentTag
                                  ? AppColors.warning
                                  : AppColors.success),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isCheckingUpdates
                              ? 'Memeriksa...'
                              : (_latestRelease != null && _latestRelease!.tagName != AppUpdateService.currentTag
                                  ? 'Versi Baru Tersedia (${_latestRelease!.tagName})'
                                  : 'Menggunakan Versi Terkini'),
                          style: TextStyle(
                            color: _isCheckingUpdates
                                ? AppColors.gold
                                : (_latestRelease != null && _latestRelease!.tagName != AppUpdateService.currentTag
                                    ? AppColors.warning
                                    : AppColors.success),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Switch: Periksa Otomatis saat App Dibuka
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.gold,
            title: const Text(
              'Periksa Pembaruan Otomatis',
              style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Deteksi rilis baru di GitHub & tampilkan popup/notifikasi saat aplikasi dibuka',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
            value: _autoCheckUpdates,
            onChanged: (val) async {
              HapticFeedback.selectionClick();
              await _storage.setAutoCheckUpdates(val);
              setState(() => _autoCheckUpdates = val);
            },
          ),
          const SizedBox(height: 12),

          // Action Buttons: Periksa Sekarang & Lihat Changelog
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isCheckingUpdates
                      ? null
                      : () async {
                          HapticFeedback.mediumImpact();
                          setState(() => _isCheckingUpdates = true);
                          MollyToast.showInfo(context, 'Memeriksa rilis terbaru di GitHub...');

                          final result = await AppUpdateService.instance.checkForUpdates(notifyIfAvailable: true);
                          if (!mounted) return;
                          setState(() {
                            _isCheckingUpdates = false;
                            _latestRelease = result.latestRelease;
                          });

                          if (result.isUpdateAvailable && result.latestRelease != null) {
                            AppUpdateDialog.show(context, result.latestRelease!);
                          } else {
                            MollyToast.showSuccess(
                              context,
                              'Molly sudah versi terkini (${AppUpdateService.currentTag}).',
                              title: 'Aplikasi Up-To-Date',
                            );
                          }
                        },
                  icon: _isCheckingUpdates
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text(
                    'Periksa Pembaruan',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: AppColors.gold.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ChangelogModal.show(context);
                  },
                  icon: const Icon(CupertinoIcons.doc_plaintext, size: 15, color: AppColors.gold),
                  label: const Text(
                    'Lihat Changelog',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStandaloneEngineStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecorations.frostedCard(blur: 20, borderColor: AppColors.gold.withOpacity(0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.bolt_fill, color: AppColors.gold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'STATUS ENGINE: 100% STANDALONE',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Berdiri Sendiri Tanpa Perantara Server',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Seluruh fungsionalitas Molly (Orkestrator Agen, Eksekusi Tools, RAG Vector Search, File Workspace, dan Basis Data) berjalan secara native di dalam perangkat.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.45),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.glassBorder, width: 0.6),
            ),
            child: Row(
              children: const [
                Icon(CupertinoIcons.checkmark_shield_fill, color: AppColors.success, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Database Offline Lokal • Zero Dependency ke Server Python',
                    style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleOAuthCard() {
    final profile = _oauth.currentProfile;
    final isAuth = _oauth.isAuthenticated;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecorations.frostedCard(
        blur: 20,
        borderColor: isAuth ? AppColors.success.withOpacity(0.5) : AppColors.gold.withOpacity(0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (isAuth ? AppColors.success : AppColors.gold).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.lock_shield_fill,
                        color: isAuth ? AppColors.success : AppColors.gold,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'GOOGLE OAUTH & GEMINI ANTIGRAVITY',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isAuth ? AppColors.success : Colors.white12).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isAuth ? AppColors.success : Colors.white24,
                    width: 0.6,
                  ),
                ),
                child: Text(
                  isAuth ? 'TERHUBUNG' : 'BELUM LOGIN',
                  style: TextStyle(
                    color: isAuth ? AppColors.success : AppColors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Gunakan akun Google Antigravity untuk menjalankan model Gemini 3.8 Flash & Pro via CloudCode internal API tanpa perlu input API key secara manual.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 14),

          if (isAuth && profile != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.glassBorder, width: 0.6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.gold.withOpacity(0.2),
                        child: Text(
                          profile.email.isNotEmpty ? profile.email[0].toUpperCase() : 'G',
                          style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name.isNotEmpty ? profile.name : 'Google User',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              profile.email,
                              style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.glassBorder, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status Token:', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                      Text(
                        profile.isExpired ? 'Kadaluarsa (Perlu Refresh)' : 'Aktif & Siap Digunakan',
                        style: TextStyle(
                          color: profile.isExpired ? AppColors.warning : AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isOAuthLoading ? null : _refreshGoogleToken,
                    icon: _isOAuthLoading
                        ? const CupertinoActivityIndicator(radius: 8, color: AppColors.gold)
                        : const Icon(CupertinoIcons.arrow_clockwise, color: AppColors.gold, size: 14),
                    label: const Text(
                      'Refresh Token',
                      style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.gold.withOpacity(0.5), width: 0.8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _signOutGoogle,
                    icon: const Icon(CupertinoIcons.square_arrow_right, color: Colors.redAccent, size: 14),
                    label: const Text(
                      'Putus Akun',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.redAccent.withOpacity(0.4), width: 0.8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _isOAuthLoading ? null : _startGoogleOAuth,
                icon: _isOAuthLoading
                    ? const CupertinoActivityIndicator(radius: 8, color: Colors.black)
                    : const Icon(CupertinoIcons.arrow_right_circle_fill, color: Colors.black, size: 18),
                label: Text(
                  _isOAuthLoading ? 'Menunggu Otentikasi Browser...' : 'Start OAuth Google (Login Antigravity)',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocalDatabaseCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecorations.frostedCard(blur: 16, borderColor: AppColors.glassBorder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(CupertinoIcons.circle_grid_hex_fill, color: AppColors.gold, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'DATABASE SQLITE LOKAL HP',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.arrow_clockwise, color: AppColors.textTertiary, size: 16),
                onPressed: _refreshDbStats,
                tooltip: 'Refresh Statistik Database',
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Berkas basis data relasional SQLite tersimpan terisolasi di sandbox internal perangkat smartphone Anda.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.glassBorder, width: 0.5),
            ),
            child: Column(
              children: [
                _dbRow('Berkas Basis Data:', 'molly_standalone_v2.db'),
                const SizedBox(height: 6),
                _dbRow('Tipe Mesin DB:', 'SQLite Embedded (Pure On-Device)'),
                const SizedBox(height: 6),
                _dbRow('Lokasi Penyimpanan:', 'App Internal Sandbox Directory'),
                const Divider(color: AppColors.glassBorder, height: 16),
                if (_isLoadingDb)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CupertinoActivityIndicator(color: AppColors.gold),
                  )
                else ...[
                  _dbRow('Jumlah Sesi Chat:', '${_dbStats['sessions']} sesi'),
                  const SizedBox(height: 4),
                  _dbRow('Pesan Terarsip:', '${_dbStats['messages']} pesan'),
                  const SizedBox(height: 4),
                  _dbRow('Koleksi Agen Lokal:', '${_dbStats['agents']} agen'),
                  const SizedBox(height: 4),
                  _dbRow('Dataset Knowledge (RAG):', '${_dbStats['knowledge_datasets']} set (${_dbStats['knowledge_chunks']} chunks)'),
                  const SizedBox(height: 4),
                  _dbRow('Berkas Workspace Lokal:', '${_dbStats['workspace_files']} file'),
                  const SizedBox(height: 4),
                  _dbRow('Antrean Jobs:', '${_dbStats['background_jobs']} tugas'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: _vacuumDatabase,
              icon: const Icon(CupertinoIcons.sparkles, color: AppColors.gold, size: 16),
              label: const Text(
                'Optimasi & Defraksi SQLite (VACUUM)',
                style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.gold.withOpacity(0.4), width: 0.8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dbRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _buildDirectProviderCard() {
    final isAntigravity = _activeProvider == 'Gemini Antigravity';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecorations.frostedCard(blur: 20, borderColor: AppColors.glassBorder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(CupertinoIcons.cloud_fill, color: AppColors.gold, size: 18),
              SizedBox(width: 8),
              Text(
                'KONEKSI MODEL INFERENSI (DIRECT CLOUD / LOCAL LLM)',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Aplikasi melakukan streaming token langsung via HTTPS dari ponsel ke provider AI pilihan Anda (tanpa perantara server).',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pilih Provider LLM Aktif:',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _providers.map((p) {
              final isSel = _activeProvider == p;
              return ChoiceChip(
                label: Text(p),
                selected: isSel,
                onSelected: (_) => _onSelectProvider(p),
                selectedColor: AppColors.gold,
                backgroundColor: AppColors.surfaceElevated,
                labelStyle: TextStyle(
                  color: isSel ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: BorderSide(
                  color: isSel ? AppColors.gold : AppColors.glassBorder,
                  width: 0.6,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          if (isAntigravity) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 0.6),
              ),
              child: Row(
                children: const [
                  Icon(CupertinoIcons.info_circle_fill, color: AppColors.gold, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Provider Gemini Antigravity menggunakan token OAuth dari kartu Google OAuth di atas.',
                      style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pilih Model Gemini Antigravity:',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _antigravityModels.map((m) {
                final isCur = _modelController.text == m;
                return ChoiceChip(
                  label: Text(m, style: const TextStyle(fontSize: 11)),
                  selected: isCur,
                  onSelected: (_) {
                    setState(() => _modelController.text = m);
                    _saveDirectSettings();
                  },
                  selectedColor: AppColors.gold.withOpacity(0.8),
                  backgroundColor: AppColors.surfaceElevated,
                  labelStyle: TextStyle(
                    color: isCur ? Colors.black : Colors.white70,
                    fontWeight: isCur ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: isCur ? AppColors.gold : AppColors.glassBorder,
                    width: 0.5,
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            Text(
              _activeProvider == 'Ollama' ? 'Endpoint Ollama Lokal (HP/LAN):' : 'API Key $_activeProvider:',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.glassBorder, width: 0.6),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _apiKeyController,
                      obscureText: _activeProvider == 'Ollama' ? false : _obscureApiKey,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: _activeProvider == 'Ollama'
                            ? 'http://localhost:11434 atau IP lokal'
                            : 'sk-...',
                        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_activeProvider != 'Ollama')
                    IconButton(
                      icon: Icon(
                        _obscureApiKey ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                        color: AppColors.textTertiary,
                        size: 16,
                      ),
                      onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nama Model Default:',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: _isFetchingLiveModels ? null : _fetchLiveModelsFromProvider,
                  icon: _isFetchingLiveModels
                      ? const CupertinoActivityIndicator(radius: 6, color: AppColors.gold)
                      : const Icon(CupertinoIcons.cloud_download, size: 14, color: AppColors.gold),
                  label: Text(
                    _isFetchingLiveModels ? 'Menghubungi API...' : 'Tarik Model Real (API)',
                    style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.glassBorder, width: 0.6),
              ),
              child: TextField(
                controller: _modelController,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: 'e.g. gpt-4o, claude-3-5-sonnet, gemini-1.5-flash',
                  hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _saveDirectSettings,
              icon: const Icon(CupertinoIcons.checkmark_alt, color: Colors.black, size: 16),
              label: const Text(
                'Simpan Konfigurasi Mandiri',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrashlyticsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecorations.frostedCard(blur: 16, borderColor: Colors.redAccent.withOpacity(0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.exclamationmark_shield_fill, color: Colors.redAccent, size: 16),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'GOOGLE FIREBASE CRASHLYTICS',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.3), width: 0.8),
                ),
                child: const Text(
                  'AKTIF',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Pemantauan crash dan error diagnostik real-time terintegrasi langsung dengan SDK Google Crashlytics. Seluruh unhandled exception otomatis dikirim ke konsol Firebase.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    try {
                      await FirebaseCrashlytics.instance.log("Uji coba pengiriman log diagnostik dari pengguna");
                      await FirebaseCrashlytics.instance.recordError(
                        Exception("Manual Diagnostic Test Error (Non-Fatal)"),
                        StackTrace.current,
                        reason: 'Pengujian diagnostik telemetri Crashlytics',
                      );
                      if (context.mounted) {
                        MollyToast.showSuccess(
                          context,
                          'Log diagnostik non-fatal berhasil dikirim ke Google Crashlytics!',
                          title: 'Diagnostik Terkirim',
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        MollyToast.showError(
                          context,
                          'Crashlytics error: $e',
                          title: 'Pengiriman Gagal',
                        );
                      }
                    }
                  },
                  icon: const Icon(CupertinoIcons.doc_plaintext, size: 14, color: Colors.white),
                  label: const Text('Kirim Log Non-Fatal', style: TextStyle(color: Colors.white, fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    showCupertinoDialog(
                      context: context,
                      builder: (ctx) => CupertinoAlertDialog(
                        title: const Text('Uji Coba Crash Fatal'),
                        content: const Text(
                          'Aplikasi akan dipaksa crash seketika menggunakan FirebaseCrashlytics.instance.crash() untuk memverifikasi stack trace di Firebase Console. Lanjutkan?',
                        ),
                        actions: [
                          CupertinoDialogAction(
                            isDefaultAction: true,
                            child: const Text('Batal'),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            child: const Text('Crash Sekarang'),
                            onPressed: () {
                              Navigator.pop(ctx);
                              FirebaseCrashlytics.instance.crash();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(CupertinoIcons.flame_fill, size: 14, color: Colors.white),
                  label: const Text('Test Crash (Fatal)', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecorations.frostedCard(blur: 16, borderColor: AppColors.glassBorder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(CupertinoIcons.info_circle_fill, color: AppColors.gold, size: 18),
              SizedBox(width: 8),
              Text(
                'TENTANG MOLLY STANDALONE STUDIO',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Molly Cross-Platform adalah arsitektur mandiri berstandar Apple HIG dan Anti-UI Slop. Aplikasi berjalan 100% on-device menggunakan SQLite internal, Google OAuth Antigravity, dan engine agen lokal tanpa memerlukan server eksternal.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Versi Arsitektur:', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
              Text('2.7.2 Standalone + Antigravity OAuth', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
