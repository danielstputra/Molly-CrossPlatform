import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/database/molly_local_database.dart';
import '../../core/models/agent_preset.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_decorations.dart';
import '../../core/widgets/glass_app_bar.dart';
import '../../core/widgets/molly_toast.dart';
import '../../core/widgets/molly_text_field.dart';

class AgentsScreen extends StatefulWidget {
  final ValueChanged<AgentPreset>? onSelectAgent;

  const AgentsScreen({super.key, this.onSelectAgent});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {
  List<AgentPreset> _allAgents = [];
  List<AgentPreset> _filteredAgents = [];
  bool _loading = false;
  String _selectedCategory = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Semua',
    'Engineering',
    'Web & AI',
    'Automation',
    'Security',
    'Data & Analytics',
    'Creative & Multimedia',
  ];

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    setState(() => _loading = true);
    final list = await MollyLocalDatabase.instance.getAgents();
    if (mounted) {
      setState(() {
        _allAgents = list;
        _applyFilter();
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredAgents = _allAgents.filter((agent) {
        final matchesCat = _selectedCategory == 'Semua' ||
            agent.category.toLowerCase() == _selectedCategory.toLowerCase();
        final matchesQuery = query.isEmpty ||
            agent.name.toLowerCase().contains(query) ||
            agent.description.toLowerCase().contains(query) ||
            agent.skills.any((s) => s.toLowerCase().contains(query));
        return matchesCat && matchesQuery;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Katalog Agen & Skills Marketplace',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.plus_circle_fill, color: AppColors.gold, size: 22),
            tooltip: 'Buat Agen Kustom',
            onPressed: _showCreateAgentDialog,
          ),
          IconButton(
            onPressed: _loading ? null : _loadAgents,
            icon: _loading
                ? const CupertinoActivityIndicator(color: AppColors.gold)
                : const Icon(CupertinoIcons.arrow_clockwise, color: AppColors.gold, size: 20),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final int cols = width < 720 ? 1 : (width < 1100 ? 2 : 3);

          return Column(
            children: [
              _buildSearchBar(),
              _buildCategoryPills(),
              Expanded(
                child: _loading
                    ? const Center(child: CupertinoActivityIndicator(color: AppColors.gold, radius: 14))
                    : _filteredAgents.isEmpty
                        ? _buildEmptyState()
                        : _buildAgentsGrid(cols),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        height: 44,
        decoration: GlassDecorations.frostedCard(blur: 16, borderColor: AppColors.glassBorder),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => _applyFilter(),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Cari agen, keahlian (misal: browser-use, vercel-ai, docker)...',
            hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
            prefixIcon: const Icon(CupertinoIcons.search, color: AppColors.gold, size: 18),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(CupertinoIcons.clear_circled_solid, color: AppColors.textTertiary, size: 16),
                    onPressed: () {
                      _searchController.clear();
                      _applyFilter();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPills() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedCategory = cat;
                _applyFilter();
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.gold.withOpacity(0.18) : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.gold.withOpacity(0.45) : AppColors.glassBorder,
                  width: 0.6,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: isSelected ? AppColors.gold : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAgentsGrid(int cols) {
    if (cols == 1) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 125),
        itemCount: _filteredAgents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final agent = _filteredAgents[index];
          return _buildAgentCard(agent);
        },
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 125),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.45,
      ),
      itemCount: _filteredAgents.length,
      itemBuilder: (context, index) {
        final agent = _filteredAgents[index];
        return _buildAgentCard(agent);
      },
    );
  }

  void _showCreateAgentDialog([AgentPreset? existingAgent]) {
    final isEditing = existingAgent != null;
    final nameCtrl = TextEditingController(text: existingAgent?.name ?? '');
    final descCtrl = TextEditingController(text: existingAgent?.description ?? '');
    final promptCtrl = TextEditingController(text: existingAgent?.systemPrompt ?? '');
    final skillsCtrl = TextEditingController(text: existingAgent != null ? existingAgent.skills.join(', ') : '');
    String cat = existingAgent?.category ?? 'Engineering';
    String model = existingAgent?.model ?? 'gemini-3.8-flash-medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 0.8),
            ),
            child: SingleChildScrollView(
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
                  Text(
                    isEditing ? 'UBAH AGEN AI KUSTOM' : 'BUAT AGEN AI KUSTOM BARU',
                    style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 12),
                  MollyTextField(
                    controller: nameCtrl,
                    labelText: 'Nama Agen',
                    hintText: 'Misal: Senior Code Reviewer',
                  ),
                  const SizedBox(height: 10),
                  MollyTextField(
                    controller: descCtrl,
                    labelText: 'Deskripsi Keahlian',
                    hintText: 'Misal: Ahli audit performa dan clean architecture',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  MollyTextField(
                    controller: promptCtrl,
                    labelText: 'System Prompt Instruksi Agen',
                    hintText: 'Tuliskan instruksi perilaku agen AI di sini...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  MollyTextField(
                    controller: skillsCtrl,
                    labelText: 'Daftar Skills (pisahkan dengan koma)',
                    hintText: 'e.g. anti-ui-slop, debugger, python-testing-patterns',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      icon: const Icon(CupertinoIcons.checkmark_alt, size: 16, color: Colors.black),
                      label: Text(
                        isEditing ? 'Perbarui Agen di SQLite Lokal' : 'Simpan Agen ke SQLite Lokal',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;

                        final savedAgent = AgentPreset(
                          id: isEditing ? existingAgent.id : 'agent-${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          category: cat,
                          description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : 'Agen Kustom Mandiri',
                          model: model,
                          skills: skillsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                          systemPrompt: promptCtrl.text.trim().isNotEmpty ? promptCtrl.text.trim() : 'Anda adalah agen AI kustom.',
                          isCustom: true,
                        );

                        await MollyLocalDatabase.instance.saveAgent(savedAgent);
                        Navigator.pop(ctx);
                        await _loadAgents();
                        if (mounted) {
                          MollyToast.showSuccess(
                            context,
                            isEditing
                                ? 'Agen "${savedAgent.name}" berhasil diperbarui!'
                                : 'Agen "${savedAgent.name}" berhasil disimpan di SQLite lokal!',
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAgent(AgentPreset agent) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Hapus Agen Kustom', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          'Apakah Anda yakin ingin menghapus agen "${agent.name}" dari basis data lokal HP?',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteAgent(agent.id);
      await _loadAgents();
      if (mounted) {
        MollyToast.showSuccess(context, 'Agen "${agent.name}" berhasil dihapus dari SQLite.');
      }
    }
  }

  Widget _buildAgentCard(AgentPreset agent) {
    return InkWell(
      onTap: () => _showAgentDetailSheet(agent),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: GlassDecorations.frostedCard(
          blur: 16,
          borderColor: AppColors.glassBorder,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 0.6),
                  ),
                  child: const Icon(CupertinoIcons.sparkles, color: AppColors.gold, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent.name,
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
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                agent.model,
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            agent.category,
                            style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                agent.description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: agent.skills.take(3).map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.glassBorder, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.wrench_fill, color: AppColors.textTertiary, size: 9),
                      const SizedBox(width: 4),
                      Text(
                        skill,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showAgentDetailSheet(AgentPreset agent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(CupertinoIcons.sparkles, color: Colors.black, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agent.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${agent.category} • Model: ${agent.model}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.glassBorder, height: 1),
              const SizedBox(height: 16),
              const Text(
                'DESKRIPSI TUGAS & TANGGUNG JAWAB',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                agent.description,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 18),
              const Text(
                'SKILLS & CAPABILITIES TERHUBUNG',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: agent.skills.map((s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.gold.withOpacity(0.25), width: 0.6),
                    ),
                    child: Text(
                      s,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              if (agent.isCustom) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showCreateAgentDialog(agent);
                        },
                        icon: const Icon(CupertinoIcons.pencil, size: 14, color: AppColors.gold),
                        label: const Text('Ubah Agen', style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.gold, width: 0.8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteAgent(agent);
                        },
                        icon: const Icon(CupertinoIcons.trash, size: 14, color: Color(0xFFEF4444)),
                        label: const Text('Hapus Agen', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEF4444), width: 0.8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    if (widget.onSelectAgent != null) {
                      widget.onSelectAgent!(agent);
                    }
                  },
                  icon: const Icon(CupertinoIcons.chat_bubble_2_fill, color: Colors.black, size: 18),
                  label: const Text(
                    'Mulai Sesi Chat Dengan Agen Ini',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(CupertinoIcons.search, color: AppColors.textTertiary, size: 40),
          SizedBox(height: 12),
          Text(
            'Tidak ada agen yang sesuai filter.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

extension _IterableFilter<T> on Iterable<T> {
  Iterable<T> filter(bool Function(T) test) sync* {
    for (final element in this) {
      if (test(element)) yield element;
    }
  }
}
