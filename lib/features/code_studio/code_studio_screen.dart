import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/database/molly_local_database.dart';
import '../../core/engine/molly_python_runner.dart';
import '../../core/engine/molly_workspace_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_decorations.dart';
import '../../core/widgets/code_block_viewer.dart';
import '../../core/widgets/glass_app_bar.dart';

class CodeStudioScreen extends StatefulWidget {
  const CodeStudioScreen({super.key});

  @override
  State<CodeStudioScreen> createState() => _CodeStudioScreenState();
}

class _CodeStudioScreenState extends State<CodeStudioScreen> {
  int _activeTab = 0; // 0 = Perubahan Kode & Diff, 1 = Worktree Terisolasi
  bool _loading = false;

  final _db = MollyLocalDatabase.instance;
  final _workspace = MollyWorkspaceEngine.instance;

  List<Map<String, dynamic>> _localFiles = [];
  String _selectedFileName = '';
  String _selectedFileDiff = '';

  final TextEditingController _newBranchController = TextEditingController();
  final List<String> _isolatedBranches = ['main'];
  String _activeBranch = 'main';

  @override
  void initState() {
    super.initState();
    _refreshLocalData();
  }

  Future<void> _refreshLocalData() async {
    setState(() => _loading = true);
    try {
      final files = await _workspace.listFiles();
      setState(() {
        _localFiles = files;
        if (_localFiles.isNotEmpty && _selectedFileName.isEmpty) {
          _selectFile(_localFiles.first);
        }
      });
    } catch (e) {
      debugPrint('Error loading local code studio: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectFile(Map<String, dynamic> file) {
    final name = file['file_name']?.toString() ?? 'unknown';
    final content = file['file_content']?.toString() ?? '';
    final diffObj = _workspace.computeDiff(
      fileName: name,
      oldContent: '// Versi Dasar Awal\n',
      newContent: content,
    );

    setState(() {
      _selectedFileName = name;
      _selectedFileDiff = diffObj.formattedDiff;
    });
  }

  void _createIsolatedBranch() {
    final name = _newBranchController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      if (!_isolatedBranches.contains(name)) {
        _isolatedBranches.add(name);
      }
      _activeBranch = name;
      _newBranchController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cabang terisolasi "$name" berhasil dibuat di memori HP!'),
        backgroundColor: AppColors.surfaceElevated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Molly Code Studio',
        subtitle: 'Cabang: $_activeBranch • ${_localFiles.length} berkas di SQLite HP',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.plus_circle_fill, color: AppColors.gold, size: 22),
            tooltip: 'Buat Berkas Baru',
            onPressed: _showCreateFileDialog,
          ),
          IconButton(
            icon: _loading
                ? const CupertinoActivityIndicator(radius: 8, color: AppColors.gold)
                : const Icon(CupertinoIcons.arrow_clockwise, color: AppColors.gold, size: 18),
            onPressed: () {
              HapticFeedback.lightImpact();
              _refreshLocalData();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Apple-style Segmented Tab Control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.glassBorder, width: 0.8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      index: 0,
                      label: 'Perubahan Kode & Diff (${_localFiles.length})',
                      icon: CupertinoIcons.doc_plaintext,
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      index: 1,
                      label: 'Worktree Terisolasi (${_isolatedBranches.length})',
                      icon: CupertinoIcons.arrow_branch,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab Content
          Expanded(
            child: _loading
                ? const Center(child: CupertinoActivityIndicator(color: AppColors.gold, radius: 14))
                : _activeTab == 0
                    ? _buildDiffView()
                    : _buildWorktreesView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({required int index, required String label, required IconData icon}) {
    final isSelected = _activeTab == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _activeTab = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withOpacity(0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: AppColors.gold.withOpacity(0.4), width: 0.6)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isSelected ? AppColors.gold : AppColors.textTertiary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiffView() {
    if (_localFiles.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: GlassDecorations.frostedCard(blur: 16, borderColor: AppColors.glassBorder),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(CupertinoIcons.checkmark_shield_fill, color: Color(0xFF10B981), size: 38),
              SizedBox(height: 12),
              Text(
                'Working Tree Bersih di Database HP',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Tidak ada perubahan kode yang tertunda. Buat berkas baru di Personal Space untuk mulai coding.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSplit = constraints.maxWidth >= 768;

        if (isSplit) {
          return Row(
            children: [
              SizedBox(
                width: 260,
                child: _buildFileList(),
              ),
              const VerticalDivider(color: AppColors.glassBorder, width: 1),
              Expanded(
                child: _buildDiffEditor(),
              ),
            ],
          );
        }

        return Column(
          children: [
            SizedBox(height: 110, child: _buildFileList()),
            const Divider(color: AppColors.glassBorder, height: 1),
            Expanded(child: _buildDiffEditor()),
          ],
        );
      },
    );
  }

  Widget _buildFileList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _localFiles.length,
      itemBuilder: (context, index) {
        final file = _localFiles[index];
        final name = file['file_name']?.toString() ?? 'file';
        final isSelected = _selectedFileName == name;

        return InkWell(
          onTap: () => _selectFile(file),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.gold.withOpacity(0.16) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: AppColors.gold.withOpacity(0.4), width: 0.6)
                  : null,
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.doc_text, size: 14, color: AppColors.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiffEditor() {
    if (_selectedFileName.isEmpty) {
      return const Center(
        child: Text('Pilih berkas untuk melihat perbandingan diff baris.', style: TextStyle(color: AppColors.textTertiary)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedFileName,
                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _runCurrentFile,
                    icon: const Icon(CupertinoIcons.play_circle_fill, color: Colors.black, size: 14),
                    label: const Text('Jalankan', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(CupertinoIcons.pencil, color: Colors.white, size: 16),
                    tooltip: 'Edit Berkas',
                    onPressed: () {
                      final current = _localFiles.firstWhere((f) => f['file_name'] == _selectedFileName, orElse: () => {});
                      if (current.isNotEmpty) {
                        _showEditFileDialog(current);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 16),
                    tooltip: 'Hapus Berkas',
                    onPressed: _deleteCurrentFile,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          CodeBlockViewer(
            code: _selectedFileDiff.isNotEmpty ? _selectedFileDiff : '// Tidak ada perbedaan konten.\n',
            language: 'diff',
            fileName: '$_selectedFileName (Diff Engine Lokal)',
          ),
        ],
      ),
    );
  }

  Future<void> _runCurrentFile() async {
    final current = _localFiles.firstWhere((f) => f['file_name'] == _selectedFileName, orElse: () => {});
    if (current.isEmpty) return;

    final content = current['file_content']?.toString() ?? '';
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FutureBuilder<PythonExecutionResult>(
          future: MollyPythonRunner.instance.runScript(content),
          builder: (ctx, snapshot) {
            final isRunning = snapshot.connectionState == ConnectionState.waiting;
            final res = snapshot.data;

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.65,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0E12),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 0.8),
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
                              color: AppColors.gold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(CupertinoIcons.terminal, color: AppColors.gold, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Terminal: $_selectedFileName',
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                              const Text(
                                'Python 3.12 (On-Device Sandboxed Runner)',
                                style: TextStyle(color: AppColors.textTertiary, fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (!isRunning && res != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: res.isSuccess
                                ? const Color(0xFF10B981).withOpacity(0.2)
                                : Colors.redAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            res.isSuccess ? 'EXIT 0 (${res.durationMs}ms)' : 'EXIT ${res.exitCode}',
                            style: TextStyle(
                              color: res.isSuccess ? const Color(0xFF10B981) : Colors.redAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.glassBorder, height: 1),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: isRunning
                          ? const Center(
                              child: CupertinoActivityIndicator(color: AppColors.gold, radius: 12),
                            )
                          : SingleChildScrollView(
                              child: SelectableText(
                                res?.stderr.isNotEmpty == true
                                    ? res!.stderr
                                    : (res?.stdout ?? 'Tidak ada output.'),
                                style: TextStyle(
                                  color: res?.isSuccess == true ? const Color(0xFFE2E8F0) : const Color(0xFFF87171),
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  height: 1.45,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: isRunning || res == null
                            ? null
                            : () {
                                final text = res.stderr.isNotEmpty ? res.stderr : res.stdout;
                                Clipboard.setData(ClipboardData(text: text));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Output terminal berhasil disalin!'), behavior: SnackBarBehavior.floating),
                                );
                              },
                        icon: const Icon(CupertinoIcons.doc_on_doc, size: 14, color: AppColors.gold),
                        label: const Text('Salin Output', style: TextStyle(color: AppColors.gold, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceElevated,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Tutup', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateFileDialog() {
    final nameCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
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
              const Text(
                'BUAT BERKAS KODE BARU DI SQLITE HP',
                style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  labelText: 'Nama Berkas (misal: main.dart, service.py, agent.ts)',
                  labelStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contentCtrl,
                maxLines: 8,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  labelText: 'Isi Kode Program...',
                  labelStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  icon: const Icon(CupertinoIcons.checkmark_alt, size: 16, color: Colors.black),
                  label: const Text('Simpan Berkas ke Workspace', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    await _workspace.createFile(fileName: name, content: contentCtrl.text);
                    Navigator.pop(ctx);
                    await _refreshLocalData();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditFileDialog(Map<String, dynamic> file) {
    final name = file['file_name']?.toString() ?? '';
    final contentCtrl = TextEditingController(text: file['file_content']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
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
              Text('Edit Berkas: $name', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              TextField(
                controller: contentCtrl,
                maxLines: 10,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
                  onPressed: () async {
                    await _workspace.createFile(fileName: name, content: contentCtrl.text);
                    Navigator.pop(ctx);
                    await _refreshLocalData();
                  },
                  child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCurrentFile() async {
    if (_selectedFileName.isEmpty) return;
    final db = await MollyLocalDatabase.instance.database;
    await db.delete('workspace_files', where: 'file_name = ?', whereArgs: [_selectedFileName]);
    _selectedFileName = '';
    _selectedFileDiff = '';
    await _refreshLocalData();
  }

  Widget _buildWorktreesView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // Create Branch Bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: GlassDecorations.frostedCard(blur: 16, borderColor: AppColors.glassBorder),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newBranchController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Nama cabang tugas baru (misal: feat-auth-sqlite)...',
                    hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _createIsolatedBranch,
                icon: const Icon(CupertinoIcons.plus, color: Colors.black, size: 14),
                label: const Text('Buat Cabang', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'CABANG KERJA AGEN TERISOLASI DI MEMORI HP',
          style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0),
        ),
        const SizedBox(height: 10),
        ..._isolatedBranches.map((branch) {
          final isCurrent = _activeBranch == branch;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: GlassDecorations.frostedCard(blur: 16, borderColor: AppColors.glassBorder),
            child: Row(
              children: [
                const Icon(CupertinoIcons.arrow_branch, color: AppColors.gold, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        isCurrent ? 'Cabang Aktif Saat Ini' : 'Cabang Terisolasi di SQLite',
                        style: TextStyle(
                          color: isCurrent ? const Color(0xFF10B981) : AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isCurrent)
                  TextButton(
                    onPressed: () {
                      setState(() => _activeBranch = branch);
                    },
                    child: const Text('Beralih', style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
