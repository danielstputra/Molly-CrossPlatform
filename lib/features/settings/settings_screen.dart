import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/database/molly_local_database.dart';
import '../../core/services/antigravity_oauth_service.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_decorations.dart';
import '../../core/widgets/glass_app_bar.dart';

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

    try {
      final profile = await _oauth.startGoogleOAuth();
      await _storage.setActiveProvider('Gemini Antigravity');
      await _storage.setActiveModel('gemini-3.8-flash-medium');

      setState(() {
        _activeProvider = 'Gemini Antigravity';
        _modelController.text = 'gemini-3.8-flash-medium';
        _isOAuthLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(CupertinoIcons.checkmark_seal_fill, color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Berhasil terhubung ke akun ${profile.email}! Provider Gemini Antigravity aktif.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isOAuthLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Otentikasi Google OAuth Gagal: $e'),
            backgroundColor: Colors.red.shade900,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _refreshGoogleToken() async {
    HapticFeedback.selectionClick();
    setState(() => _isOAuthLoading = true);
    try {
      await _oauth.refreshAccessToken();
      setState(() => _isOAuthLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access Token Google Antigravity berhasil diperbarui!'),
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isOAuthLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui token: $e'), backgroundColor: Colors.red.shade900),
        );
      }
    }
  }

  Future<void> _signOutGoogle() async {
    HapticFeedback.mediumImpact();
    await _oauth.signOut();
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun Google Antigravity telah diputus.'),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _saveDirectSettings() async {
    HapticFeedback.mediumImpact();
    await _storage.setApiKey(_activeProvider, _apiKeyController.text.trim());
    await _storage.setActiveModel(_modelController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Konfigurasi provider $_activeProvider berhasil disimpan!'),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
        ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SQLite VACUUM selesai! Basis data lokal berhasil dioptimasi.'),
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal optimasi database: $e'), backgroundColor: Colors.red.shade900),
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          _buildStandaloneEngineStatusCard(),
          const SizedBox(height: 18),
          _buildGoogleOAuthCard(),
          const SizedBox(height: 18),
          _buildLocalDatabaseCard(),
          const SizedBox(height: 18),
          _buildDirectProviderCard(),
          const SizedBox(height: 18),
          _buildAboutCard(),
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
              Row(
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
                  const Text(
                    'GOOGLE OAUTH & GEMINI ANTIGRAVITY',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
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
            const Text(
              'Nama Model Default:',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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
              Text('2.6.0 Standalone + Antigravity OAuth', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
