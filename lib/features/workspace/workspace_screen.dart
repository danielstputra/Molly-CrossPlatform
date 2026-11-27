import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/database/molly_local_database.dart';
import '../../core/engine/molly_workspace_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_decorations.dart';
import '../../core/widgets/glass_app_bar.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  final _db = MollyLocalDatabase.instance;
  final _workspace = MollyWorkspaceEngine.instance;

  bool _loading = false;
  List<Map<String, dynamic>> _files = [];

  @override
  void initState() {
    super.initState();
    _loadLocalFiles();
  }

  Future<void> _loadLocalFiles() async {
    setState(() => _loading = true);
    final files = await _workspace.listFiles();
    if (mounted) {
      setState(() {
        _files = files;
        _loading = false;
      });
    }
  }

  void _showCreateFileDialog() {
    final nameCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 0.8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Buat Berkas Baru di SQLite HP',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Berkas akan disimpan langsung ke tabel workspace_files di memori HP Anda.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Nama Berkas (misal: main.dart atau model.py)',
                    labelStyle: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    labelText: 'Isi Kode / Teks...',
                    labelStyle: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final content = contentCtrl.text;
                      if (name.isEmpty) return;

                      await _workspace.createFile(
                        fileName: name,
                        content: content,
                        fileType: name.endsWith('.dart') ? 'application/dart' : 'text/plain',
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        _loadLocalFiles();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Simpan ke Database HP', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Personal Space & Workspace',
        showBackButton: false,
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadLocalFiles,
            icon: _loading
                ? const CupertinoActivityIndicator(color: AppColors.gold, radius: 8)
                : const Icon(CupertinoIcons.arrow_clockwise, color: AppColors.gold, size: 18),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BERKAS PROYEK DI SQLITE LOKAL HP',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showCreateFileDialog,
                icon: const Icon(CupertinoIcons.plus, color: Colors.black, size: 14),
                label: const Text(
                  'Buat Berkas',
                  style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CupertinoActivityIndicator(color: AppColors.gold, radius: 12),
              ),
            )
          else if (_files.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: GlassDecorations.frostedCard(blur: 16, borderColor: AppColors.glassBorder),
              child: Column(
                children: const [
                  Icon(CupertinoIcons.folder_badge_plus, color: AppColors.textTertiary, size: 40),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada berkas di database SQLite HP Anda.',
                    style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Klik "Buat Berkas" untuk menyimpan kode sumber atau dokumen langsung ke SQLite memori HP.',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ..._files.map((file) {
              final name = file['file_name']?.toString() ?? 'Berkas';
              final path = file['file_path']?.toString() ?? '';
              final size = file['size_bytes'] ?? 0;
              final updated = file['updated_at']?.toString() ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: GlassDecorations.frostedCard(blur: 16, borderColor: AppColors.glassBorder),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 0.6),
                      ),
                      child: const Icon(CupertinoIcons.doc_text_fill, color: AppColors.gold, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$path • $size bytes',
                            style: const TextStyle(color: AppColors.textTertiary, fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'SQLITE',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
