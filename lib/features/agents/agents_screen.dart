import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/data/skills_catalog_data.dart';
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
  int _activeTab = 0; // 0 = Agen AI Aktif, 1 = Marketplace Keahlian (Skills Hub)

  // AGENTS STATE
  List<AgentPreset> _allAgents = [];
  List<AgentPreset> _filteredAgents = [];
  bool _loadingAgents = false;
  String _selectedAgentCategory = 'Semua';
  final TextEditingController _agentSearchCtrl = TextEditingController();

  final List<String> _agentCategories = [
    'Semua',
    'Engineering',
    'Web & AI',
    'Automation',
    'Security',
    'Data & Analytics',
    'Creative & Multimedia',
  ];

  // SKILLS STATE (611+ Skills Catalog)
  List<MollySkillItem> _allSkills = [];
  List<MollySkillItem> _filteredSkills = [];
  Set<String> _installedSkillIds = {};
  bool _loadingSkills = false;
  String _selectedSkillCategory = 'Semua';
  final TextEditingController _skillSearchCtrl = TextEditingController();

  final List<String> _skillCategories = [
    'Semua',
    'Security & Pen-testing',
    'Frontend & UI',
    'DevOps & Cloud',
    'AI & LLM',
    'Data & Database',
    'Software Engineering',
    'Business & Strategy',
    'Creative & Audio',
    'Mobile & Device',
  ];

  @override
  void initState() {
    super.initState();
    _loadAgents();
    _loadSkills();
  }

  @override
  void dispose() {
    _agentSearchCtrl.dispose();
    _skillSearchCtrl.dispose();
    super.dispose();
  }

  // ==========================================
  // AGENTS LOGIC
  // ==========================================

  Future<void> _loadAgents() async {
    setState(() => _loadingAgents = true);
    final list = await MollyLocalDatabase.instance.getAgents();
    if (mounted) {
      setState(() {
        _allAgents = list;
        _applyAgentFilter();
        _loadingAgents = false;
      });
    }
  }

  void _applyAgentFilter() {
    final query = _agentSearchCtrl.text.toLowerCase().trim();
    setState(() {
      _filteredAgents = _allAgents.where((agent) {
        final matchesCat = _selectedAgentCategory == 'Semua' ||
            agent.category.toLowerCase() == _selectedAgentCategory.toLowerCase();
        final matchesQuery = query.isEmpty ||
            agent.name.toLowerCase().contains(query) ||
            agent.description.toLowerCase().contains(query) ||
            agent.skills.any((s) => s.toLowerCase().contains(query));
        return matchesCat && matchesQuery;
      }).toList();
    });
  }

  // ==========================================
  // SKILLS LOGIC
  // ==========================================

  Future<void> _loadSkills() async {
    setState(() => _loadingSkills = true);
    final installedIds = await MollyLocalDatabase.instance.getInstalledSkillIds();
    final rawSkills = SkillsCatalogData.allSkills;

    if (mounted) {
      setState(() {
        _installedSkillIds = installedIds;
        _allSkills = rawSkills.map((s) {
          return s.copyWith(isInstalled: _installedSkillIds.contains(s.id));
        }).toList();
        _applySkillFilter();
        _loadingSkills = false;
      });
    }
  }

  void _applySkillFilter() {
    final query = _skillSearchCtrl.text.toLowerCase().trim();
    setState(() {
      _filteredSkills = _allSkills.where((skill) {
        final matchesCat = _selectedSkillCategory == 'Semua' ||
            skill.category.toLowerCase() == _selectedSkillCategory.toLowerCase();
        final matchesQuery = query.isEmpty ||
            skill.name.toLowerCase().contains(query) ||
            skill.id.toLowerCase().contains(query) ||
            skill.description.toLowerCase().contains(query);
        return matchesCat && matchesQuery;
      }).toList();
    });
  }

  Future<void> _toggleSkillInstall(MollySkillItem skill) async {
    final willInstall = !_installedSkillIds.contains(skill.id);
    HapticFeedback.lightImpact();

    await MollyLocalDatabase.instance.setSkillInstalled(skill.id, willInstall);
    await _loadSkills();

    if (mounted) {
      if (willInstall) {
        MollyToast.showSuccess(
          context,
          'Keahlian "${skill.name}" berhasil dipasang ke SQLite HP!',
          title: 'Skill Terpasang',
        );
      } else {
        MollyToast.showInfo(
          context,
          'Keahlian "${skill.name}" telah dilepas dari agen aktif.',
          title: 'Skill Dilepas',
        );
      }
    }
  }

  // ==========================================
  // UI BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: _activeTab == 0
            ? 'Katalog Agen AI Mandiri'
            : 'Marketplace Keahlian (${_allSkills.length} Skills)',
        showBackButton: false,
        actions: [
          if (_activeTab == 0)
            IconButton(
              icon: const Icon(CupertinoIcons.plus_circle_fill, color: AppColors.gold, size: 22),
              tooltip: 'Buat Agen Kustom Baru',
              onPressed: () => _showCreateAgentDialog(),
            ),
          IconButton(
            onPressed: (_loadingAgents || _loadingSkills)
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    if (_activeTab == 0) {
                      _loadAgents();
                    } else {
                      _loadSkills();
                    }
                  },
            icon: (_loadingAgents || _loadingSkills)
                ? const CupertinoActivityIndicator(color: AppColors.gold)
                : const Icon(CupertinoIcons.arrow_clockwise, color: AppColors.gold, size: 20),
            tooltip: 'Segarkan',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSegmentedTab(),
          Expanded(
            child: _activeTab == 0 ? _buildAgentsTabView() : _buildSkillsTabView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
              child: _tabButton(
                index: 0,
                label: 'Agen Aktif (${_allAgents.length})',
                icon: CupertinoIcons.person_3_fill,
              ),
            ),
            Expanded(
              child: _tabButton(
                index: 1,
                label: 'Skills Hub (${_allSkills.length})',
                icon: CupertinoIcons.sparkles,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton({required int index, required String label, required IconData icon}) {
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
          color: isSelected ? AppColors.gold.withOpacity(0.18) : Colors.transparent,
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

  // ==========================================
  // TAB 0: AGENTS VIEW
  // ==========================================

  Widget _buildAgentsTabView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int cols = width < 720 ? 1 : (width < 1100 ? 2 : 3);

        return Column(
          children: [
            _buildAgentSearchBar(),
            _buildAgentCategoryPills(),
            Expanded(
              child: _loadingAgents
                  ? const Center(child: CupertinoActivityIndicator(color: AppColors.gold, radius: 14))
                  : _filteredAgents.isEmpty
                      ? _buildEmptyState('Tidak ada agen yang sesuai filter pencarian.')
                      : _buildAgentsGrid(cols),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAgentSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
        height: 42,
        decoration: GlassDecorations.frostedCard(blur: 16, borderColor: AppColors.glassBorder),
        child: TextField(
          controller: _agentSearchCtrl,
          onChanged: (_) => _applyAgentFilter(),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Cari agen, keahlian (misal: browser-use, vercel-ai, docker)...',
            hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12.5),
            prefixIcon: const Icon(CupertinoIcons.search, color: AppColors.gold, size: 17),
            suffixIcon: _agentSearchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(CupertinoIcons.clear_circled_solid, color: AppColors.textTertiary, size: 16),
                    onPressed: () {
                      _agentSearchCtrl.clear();
                      _applyAgentFilter();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
          ),
        ),
      ),
    );
  }

  Widget _buildAgentCategoryPills() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _agentCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _agentCategories[index];
          final isSelected = _selectedAgentCategory == cat;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedAgentCategory = cat;
                _applyAgentFilter();
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  fontSize: 11.5,
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
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 125),
        itemCount: _filteredAgents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final agent = _filteredAgents[index];
          return _buildAgentCard(agent, isGrid: false);
        },
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 125),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.5,
      ),
      itemCount: _filteredAgents.length,
      itemBuilder: (context, index) {
        final agent = _filteredAgents[index];
        return _buildAgentCard(agent, isGrid: true);
      },
    );
  }

  Widget _buildAgentCard(AgentPreset agent, {required bool isGrid}) {
    return InkWell(
      onTap: () => _showAgentDetailSheet(agent),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: GlassDecorations.frostedCard(
          blur: 16,
          borderColor: AppColors.glassBorder,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: isGrid ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
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
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                agent.model,
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              agent.category,
                              style: const TextStyle(color: AppColors.textTertiary, fontSize: 10.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              agent.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
                height: 1.35,
              ),
              maxLines: isGrid ? 3 : 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: agent.skills.take(3).map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.glassBorder, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.wrench_fill, color: AppColors.textTertiary, size: 8.5),
                      const SizedBox(width: 4),
                      Text(
                        skill,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9.5,
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

  // ==========================================
  // TAB 1: SKILLS HUB VIEW
  // ==========================================

  Widget _buildSkillsTabView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int cols = width < 720 ? 1 : (width < 1100 ? 2 : 3);

        return Column(
          children: [
            _buildSkillSearchBar(),
            _buildSkillCategoryPills(),
            Expanded(
              child: _loadingSkills
                  ? const Center(child: CupertinoActivityIndicator(color: AppColors.gold, radius: 14))
                  : _filteredSkills.isEmpty
                      ? _buildEmptyState('Tidak ada skill yang cocok dengan kriteria pencarian.')
                      : _buildSkillsGrid(cols),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSkillSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
        height: 42,
        decoration: GlassDecorations.frostedCard(blur: 16, borderColor: AppColors.glassBorder),
        child: TextField(
          controller: _skillSearchCtrl,
          onChanged: (_) => _applySkillFilter(),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Cari 611+ keahlian (misal: anti-ui-slop, docker, sql, jwt)...',
            hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12.5),
            prefixIcon: const Icon(CupertinoIcons.search, color: AppColors.gold, size: 17),
            suffixIcon: _skillSearchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(CupertinoIcons.clear_circled_solid, color: AppColors.textTertiary, size: 16),
                    onPressed: () {
                      _skillSearchCtrl.clear();
                      _applySkillFilter();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
          ),
        ),
      ),
    );
  }

  Widget _buildSkillCategoryPills() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _skillCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _skillCategories[index];
          final isSelected = _selectedSkillCategory == cat;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedSkillCategory = cat;
                _applySkillFilter();
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkillsGrid(int cols) {
    if (cols == 1) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 125),
        itemCount: _filteredSkills.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final skill = _filteredSkills[index];
          return _buildSkillCard(skill, isGrid: false);
        },
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 125),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: _filteredSkills.length,
      itemBuilder: (context, index) {
        final skill = _filteredSkills[index];
        return _buildSkillCard(skill, isGrid: true);
      },
    );
  }

  Widget _buildSkillCard(MollySkillItem skill, {required bool isGrid}) {
    final isInstalled = _installedSkillIds.contains(skill.id);

    return InkWell(
      onTap: () => _showSkillDetailSheet(skill),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: GlassDecorations.frostedCard(
          blur: 16,
          borderColor: isInstalled
              ? const Color(0xFF10B981).withOpacity(0.35)
              : AppColors.glassBorder,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: isGrid ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isInstalled
                        ? const Color(0xFF10B981).withOpacity(0.15)
                        : AppColors.gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isInstalled
                          ? const Color(0xFF10B981).withOpacity(0.4)
                          : AppColors.gold.withOpacity(0.3),
                      width: 0.6,
                    ),
                  ),
                  child: Icon(
                    isInstalled ? CupertinoIcons.checkmark_shield_fill : CupertinoIcons.wrench_fill,
                    color: isInstalled ? const Color(0xFF10B981) : AppColors.gold,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skill.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        skill.category,
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _toggleSkillInstall(skill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: isInstalled
                          ? const Color(0xFF10B981).withOpacity(0.16)
                          : AppColors.gold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isInstalled
                            ? const Color(0xFF10B981)
                            : AppColors.gold.withOpacity(0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      isInstalled ? 'AKTIF' : '+ PASANG',
                      style: TextStyle(
                        color: isInstalled ? const Color(0xFF10B981) : AppColors.gold,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              skill.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
                height: 1.35,
              ),
              maxLines: isGrid ? 3 : 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              'ID: ${skill.id}',
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 9.5,
                fontFamily: 'monospace',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MODALS & DETAIL SHEETS
  // ==========================================

  void _showSkillDetailSheet(MollySkillItem skill) {
    final isInstalled = _installedSkillIds.contains(skill.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final installedNow = _installedSkillIds.contains(skill.id);
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 0.8),
                        ),
                        child: const Icon(CupertinoIcons.sparkles, color: AppColors.gold, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              skill.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Kategori: ${skill.category}',
                              style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.glassBorder, height: 1),
                  const SizedBox(height: 14),
                  const Text(
                    'PANDUAN & RUANG LINGKUP KEAHLIAN (SKILL.MD):',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.glassBorder, width: 0.5),
                    ),
                    child: Text(
                      skill.description,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'IDENTIFIKATOR INTENT:',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'skill-id: ${skill.id}',
                      style: const TextStyle(color: AppColors.goldLight, fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _toggleSkillInstall(skill);
                        setSheetState(() {});
                      },
                      icon: Icon(
                        installedNow ? CupertinoIcons.trash : CupertinoIcons.checkmark_seal_fill,
                        color: installedNow ? Colors.white : Colors.black,
                        size: 16,
                      ),
                      label: Text(
                        installedNow ? 'Lepas Keahlian Ini Dari Agen' : 'Pasang Keahlian ke SQLite HP',
                        style: TextStyle(
                          color: installedNow ? Colors.white : Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: installedNow ? const Color(0xFFEF4444) : AppColors.gold,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
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
                  const SizedBox(height: 14),
                  MollyTextField(
                    controller: nameCtrl,
                    labelText: 'Nama Agen',
                    hintText: 'Misal: Next.js Fullstack Craftsman',
                  ),
                  const SizedBox(height: 10),
                  MollyTextField(
                    controller: descCtrl,
                    labelText: 'Deskripsi Keahlian Singkat',
                    hintText: 'Pakar arsitektur modern berstandar anti-slop...',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  MollyTextField(
                    controller: promptCtrl,
                    labelText: 'System Prompt Agen',
                    hintText: 'Instruksi kepribadian dan pedoman sistem untuk agen...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 10),
                  MollyTextField(
                    controller: skillsCtrl,
                    labelText: 'Keahlian Terhubung (Pisahkan dengan Koma)',
                    hintText: 'anti-ui-slop, tailwind-design-system, react-pro',
                  ),
                  const SizedBox(height: 14),
                  const Text('Pilih Model LLM:', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'gemini-3.8-flash-medium',
                        'gemini-3.8-pro',
                        'gpt-4o',
                        'claude-3-5-sonnet',
                        'llama-3.3-70b-versatile',
                      ].map((m) {
                        final isSel = model == m;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(m, style: TextStyle(fontSize: 10.5, color: isSel ? Colors.black : Colors.white)),
                            selected: isSel,
                            selectedColor: AppColors.gold,
                            backgroundColor: AppColors.surfaceElevated,
                            onSelected: (_) => setSheetState(() => model = m),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;

                        final skillsList = skillsCtrl.text
                            .split(',')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList();

                        final newPreset = AgentPreset(
                          id: isEditing ? existingAgent.id : 'agent-${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          category: cat,
                          description: descCtrl.text.trim(),
                          model: model,
                          skills: skillsList,
                          systemPrompt: promptCtrl.text.trim(),
                          isCustom: true,
                        );

                        await MollyLocalDatabase.instance.saveAgent(newPreset);
                        if (mounted) {
                          Navigator.pop(ctx);
                          _loadAgents();
                          MollyToast.showSuccess(
                            context,
                            isEditing ? 'Agen "$name" berhasil diperbarui!' : 'Agen "$name" berhasil dibuat!',
                            title: 'SQLite Disimpan',
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text(
                        isEditing ? 'Simpan Perubahan Agen' : 'Simpan Agen ke Database HP',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
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

  void _showAgentDetailSheet(AgentPreset agent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(22),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(CupertinoIcons.sparkles, color: Colors.black, size: 20),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${agent.category} • Model: ${agent.model}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: AppColors.glassBorder, height: 1),
              const SizedBox(height: 14),
              const Text(
                'DESKRIPSI TUGAS & TANGGUNG JAWAB',
                style: TextStyle(color: AppColors.gold, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.8),
              ),
              const SizedBox(height: 6),
              Text(
                agent.description,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.45),
              ),
              const SizedBox(height: 14),
              const Text(
                'SKILLS & CAPABILITIES TERHUBUNG',
                style: TextStyle(color: AppColors.gold, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.8),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 5,
                children: agent.skills.map((s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.gold.withOpacity(0.25), width: 0.5),
                    ),
                    child: Text(
                      s,
                      style: const TextStyle(color: AppColors.gold, fontSize: 10.5, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              if (agent.isCustom) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showCreateAgentDialog(agent);
                        },
                        icon: const Icon(CupertinoIcons.pencil, size: 13, color: AppColors.gold),
                        label: const Text('Ubah Agen', style: TextStyle(color: AppColors.gold, fontSize: 11.5, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.gold, width: 0.8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await MollyLocalDatabase.instance.deleteAgent(agent.id);
                          await _loadAgents();
                          if (mounted) {
                            MollyToast.showSuccess(context, 'Agen "${agent.name}" berhasil dihapus.');
                          }
                        },
                        icon: const Icon(CupertinoIcons.trash, size: 13, color: Color(0xFFEF4444)),
                        label: const Text('Hapus Agen', style: TextStyle(color: Color(0xFFEF4444), fontSize: 11.5, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEF4444), width: 0.8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
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
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    if (widget.onSelectAgent != null) {
                      widget.onSelectAgent!(agent);
                    }
                  },
                  icon: const Icon(CupertinoIcons.chat_bubble_2_fill, color: Colors.black, size: 16),
                  label: const Text(
                    'Mulai Sesi Chat Dengan Agen Ini',
                    style: TextStyle(color: Colors.black, fontSize: 13.5, fontWeight: FontWeight.w700),
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
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.search, color: AppColors.textTertiary, size: 36),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
