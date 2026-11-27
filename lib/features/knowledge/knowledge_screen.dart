import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/database/molly_local_database.dart';
import '../../core/engine/molly_knowledge_engine.dart';
import '../../core/models/knowledge_base.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_decorations.dart';
import '../../core/widgets/glass_app_bar.dart';
import '../../core/widgets/molly_toast.dart';
import '../../core/widgets/molly_text_field.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  final _db = MollyLocalDatabase.instance;
  final _engine = MollyKnowledgeEngine.instance;

  List<KnowledgeDataset> _datasets = [];
  List<SearchResultChunk> _searchResults = [];
  bool _loading = false;
  bool _searching = false;
  final TextEditingController _queryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLocalDatasets();
  }

  Future<void> _loadLocalDatasets() async {
    setState(() => _loading = true);
    final data = await _db.getDatasets();
    if (mounted) {
      setState(() {
        _datasets = data;
        _loading = false;
      });
    }
  }

  Future<void> _runSimilaritySearch() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() => _searching = true);
    final results = await _engine.searchSimilarity(query: query, topK: 3);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Knowledge Base & On-Device RAG',
        showBackButton: false,
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadLocalDatasets,
            icon: _loading
                ? const CupertinoActivityIndicator(color: AppColors.gold)
                : const Icon(CupertinoIcons.arrow_clockwise, color: AppColors.gold, size: 20),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final int cols = width < 768 ? 1 : (width < 1200 ? 2 : 3);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchTestBar(),
                if (_searchResults.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSearchResults(),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'DATASET SQLITE LOKAL HP',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showUploadModal,
                      icon: const Icon(CupertinoIcons.doc_text_fill, color: Colors.black, size: 14),
                      label: const Text(
                        'Tambah Dokumen',
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
                _loading
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CupertinoActivityIndicator(color: AppColors.gold, radius: 14),
                      ))
                    : _datasets.isEmpty
                        ? _buildEmptyState()
                        : _buildDatasetsGrid(cols),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchTestBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecorations.frostedCard(blur: 20, borderColor: AppColors.glassBorder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(CupertinoIcons.search_circle_fill, color: AppColors.gold, size: 20),
              SizedBox(width: 8),
              Text(
                'Pencarian Vektor Semantik (SQLite Kosinus Lokal)',
                style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.glassBorder, width: 0.6),
                  ),
                  child: TextField(
                    controller: _queryController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Cari chunk pengetahuan di memori lokal HP...',
                      hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    ),
                    onSubmitted: (_) => _runSimilaritySearch(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _searching ? null : _runSimilaritySearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  elevation: 0,
                ),
                child: _searching
                    ? const CupertinoActivityIndicator(color: Colors.black, radius: 8)
                    : const Text('Cari Vektor', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: GlassDecorations.frostedCard(blur: 16, borderColor: AppColors.glassBorder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'HASIL SIMILARITY SEARCH LOKAL:',
                style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.clear_circled, color: AppColors.textTertiary, size: 16),
                onPressed: () => setState(() => _searchResults = []),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ..._searchResults.map((res) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        res.docName,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Skor Kosinus: ${(res.score * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(color: AppColors.gold, fontSize: 10, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    res.text,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.4),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDatasetsGrid(int cols) {
    final df = DateFormat('dd MMM yyyy, HH:mm');

    if (cols == 1) {
      return Column(
        children: _datasets.map((d) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildDatasetCard(d, df),
        )).toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _datasets.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) => _buildDatasetCard(_datasets[index], df),
    );
  }

  Widget _buildDatasetCard(KnowledgeDataset d, DateFormat df) {
    return InkWell(
      onTap: () => _showChunksPreview(d),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: GlassDecorations.frostedCard(blur: 16, borderColor: AppColors.glassBorder),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        d.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Embedding: ${d.embeddingModel}',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.trash, color: AppColors.textTertiary, size: 16),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _deleteDataset(d.id, d.name),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              d.description,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.glassBorder, width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statItem('Dokumen', '${d.documentCount} file'),
                  _statItem('Chunks', '${d.chunkCount} vector'),
                  _statItem('Diperbarui', df.format(d.updatedAt)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChunksPreview(KnowledgeDataset d) async {
    HapticFeedback.lightImpact();
    final chunks = await _db.getChunks(datasetId: d.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      Text('${chunks.length} chunks di SQLite Lokal HP', style: const TextStyle(color: AppColors.gold, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 20), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(color: AppColors.glassBorder, height: 16),
            Expanded(
              child: chunks.isEmpty
                  ? const Center(child: Text('Belum ada chunk vektor.', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)))
                  : ListView.builder(
                      itemCount: chunks.length,
                      itemBuilder: (context, idx) {
                        final c = chunks[idx];
                        final text = c['chunk_text']?.toString() ?? '';
                        final doc = c['doc_name']?.toString() ?? 'doc';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.glassBorder, width: 0.6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Chunk #${idx + 1} • $doc', style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold)),
                                  const Icon(CupertinoIcons.checkmark_circle_fill, size: 12, color: Color(0xFF10B981)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              SelectableText(
                                text,
                                style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12, height: 1.4),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: GlassDecorations.frostedCard(blur: 16, borderColor: AppColors.glassBorder),
      child: Center(
        child: Column(
          children: const [
            Icon(CupertinoIcons.folder_badge_plus, color: AppColors.textTertiary, size: 36),
            SizedBox(height: 10),
            Text(
              'Belum ada dataset di database SQLite HP Anda.',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text(
              'Klik "Tambah Dokumen" di atas untuk menyimpan dokumen dan mengekstrak vektor lokal.',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadModal() {
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
                  'Tambah Dokumen ke SQLite Lokal',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Dokumen akan di-chunk dan disimpan langsung di database SQLite memori HP.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        backgroundColor: AppColors.surfaceElevated,
                        label: const Text('Arsitektur Molly On-Device', style: TextStyle(color: AppColors.gold, fontSize: 11)),
                        onPressed: () {
                          nameCtrl.text = 'arsitektur_molly_engine.md';
                          contentCtrl.text = '# Arsitektur Molly On-Device SQLite Engine\n\nMolly beroperasi secara mandiri di memori lokal HP menggunakan SQLite v2.\nTidak ada ketergantungan pada backend server eksternal.\nSeluruh eksekusi chat, RAG kosinus vektor, dan otomasi aBridge diproses on-device.';
                        },
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        backgroundColor: AppColors.surfaceElevated,
                        label: const Text('Pedoman Anti-UI Slop', style: TextStyle(color: AppColors.gold, fontSize: 11)),
                        onPressed: () {
                          nameCtrl.text = 'guideline_anti_ui_slop.md';
                          contentCtrl.text = '# Standar Desain Anti-UI Slop\n\n1. Seluruh margin dan padding harus menghormati MediaQuery safe area padding bottom.\n2. Tidak boleh ada komponen bertumpuk atau overlap sembarangan.\n3. Tipografi rapih dan micro-interactions 60 FPS.';
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                MollyTextField(
                  controller: nameCtrl,
                  labelText: 'Nama Dokumen',
                  hintText: 'Misal: pedoman_arsitektur.md',
                ),
                const SizedBox(height: 12),
                MollyTextField(
                  controller: contentCtrl,
                  labelText: 'Isi Dokumen Referensi',
                  hintText: 'Tempelkan dokumen referensi di sini...',
                  maxLines: 5,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final content = contentCtrl.text.trim();
                      if (name.isEmpty || content.isEmpty) return;

                      final datasetId = 'dataset-${DateTime.now().millisecondsSinceEpoch}';
                      await _db.saveDataset(KnowledgeDataset(
                        id: datasetId,
                        name: name,
                        description: 'Dokumen teks lokal tersimpan di SQLite HP.',
                        documentCount: 1,
                        updatedAt: DateTime.now(),
                      ));

                      await _engine.ingestDocument(
                        datasetId: datasetId,
                        docName: name,
                        rawContent: content,
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        _loadLocalDatasets();
                        MollyToast.showSuccess(
                          context,
                          'Dokumen "$name" berhasil diindeks ke memori RAG HP!',
                          title: 'Vektor Tersimpan',
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Simpan & Ekstrak Vektor', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteDataset(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Hapus Dataset', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text('Hapus dataset "$name" beserta semua vektor semantiknya dari SQLite lokal?', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteDataset(id);
      await _loadLocalDatasets();
    }
  }
}
