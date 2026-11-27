import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/molly_local_database.dart';
import '../../core/engine/molly_knowledge_engine.dart';
import '../../core/models/knowledge_base.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_decorations.dart';
import '../../core/widgets/glass_app_bar.dart';

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
                      icon: const Icon(CupertinoIcons.doc_badge_plus, color: Colors.black, size: 14),
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
                const SizedBox(height: 90),
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
    return Container(
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
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 0.6),
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
                    ),
                  ],
                ),
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
              color: AppColors.surfaceElevated.withValues(alpha: 0.7),
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
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 0.8),
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
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Nama Dokumen (misal: pedoman_arsitektur.md)',
                    labelStyle: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Isi Dokumen Referensi...',
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
}
