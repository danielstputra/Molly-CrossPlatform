import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/database/molly_local_database.dart';
import '../../core/engine/molly_workspace_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_decorations.dart';
import '../../core/widgets/glass_app_bar.dart';
import '../../core/widgets/molly_toast.dart';
import '../../core/widgets/molly_text_field.dart';

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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 125),
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
              final id = file['id']?.toString() ?? '';
              final name = file['file_name']?.toString() ?? 'Berkas';
              final path = file['file_path']?.toString() ?? '';
              final size = file['size_bytes'] ?? 0;
              final content = file['file_content']?.toString() ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: GlassDecorations.frostedCard(blur: 16, borderColor: AppColors.glassBorder),
                child: InkWell(
                  onTap: () => _previewFile(id, name, content),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
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
                        IconButton(
                          icon: const Icon(CupertinoIcons.trash, color: AppColors.textTertiary, size: 16),
                          onPressed: () => _deleteFile(id, name),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showRenameDialog(String id, String currentName, String content) {
    final renameCtrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Ubah Nama Berkas', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: MollyTextField(
          controller: renameCtrl,
          labelText: 'Nama Berkas Baru',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = renameCtrl.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                await _workspace.deleteFile(id);
                await _workspace.createFile(fileName: newName, content: content);
                Navigator.pop(ctx);
                _loadLocalFiles();
                if (mounted) {
                  MollyToast.showSuccess(context, 'Nama berkas diubah menjadi "$newName"');
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: const Text('Simpan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _previewFile(String id, String name, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1117),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      icon: const Icon(CupertinoIcons.pencil, size: 14, color: AppColors.gold),
                      label: const Text('Edit', style: TextStyle(color: AppColors.gold, fontSize: 12)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showEditFileDialog(name, content);
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(CupertinoIcons.pencil_ellipsis_rectangle, size: 14, color: AppColors.gold),
                      label: const Text('Ubah Nama', style: TextStyle(color: AppColors.gold, fontSize: 12)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showRenameDialog(id, name, content);
                      },
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.doc_on_clipboard, color: AppColors.textTertiary, size: 16),
                      tooltip: 'Salin Isi',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: content));
                        MollyToast.showSuccess(context, 'Isi berkas berhasil disalin!');
                      },
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 20), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ],
            ),
            const Divider(color: AppColors.glassBorder),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  content.isNotEmpty ? content : '// Berkas kosong',
                  style: const TextStyle(color: Color(0xFFE2E8F0), fontFamily: 'monospace', fontSize: 12, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditFileDialog(String name, String content) {
    final editCtrl = TextEditingController(text: content);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1117),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Edit: $name',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      await _workspace.saveFile(name, editCtrl.text);
                      if (mounted) {
                        Navigator.pop(ctx);
                        _loadLocalFiles();
                        MollyToast.showSuccess(
                          context,
                          'Perubahan "$name" berhasil disimpan di SQLite lokal!',
                          title: 'Berkas Disimpan',
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Simpan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const Divider(color: AppColors.glassBorder, height: 16),
              Expanded(
                child: TextField(
                  controller: editCtrl,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(color: Color(0xFFE2E8F0), fontFamily: 'monospace', fontSize: 12, height: 1.45),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Tulis kode atau teks di sini...',
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteFile(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Hapus Berkas', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text('Hapus "$name" dari memori SQLite?', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: AppColors.textTertiary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      await _workspace.deleteFile(id);
      await _loadLocalFiles();
    }
  }
}
