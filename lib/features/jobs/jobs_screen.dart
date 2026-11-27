import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/database/molly_local_database.dart';
import '../../core/models/background_job.dart';
import '../../core/models/extension_tool.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_decorations.dart';
import '../../core/widgets/glass_app_bar.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final _service = MollyStudioService.instance;
  int _activeTab = 0; // 0 = Jobs & Crons, 1 = Extensions & MCP Tools
  List<BackgroundJob> _jobs = [];
  List<ExtensionTool> _tools = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final jobs = await MollyLocalDatabase.instance.getBackgroundJobs();
    final tools = await MollyLocalDatabase.instance.getMcpTools();
    if (mounted) {
      setState(() {
        _jobs = jobs;
        _tools = tools;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Background Jobs & MCP Registry',
        showBackButton: false,
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadData,
            icon: _loading
                ? const CupertinoActivityIndicator(color: AppColors.gold)
                : const Icon(CupertinoIcons.arrow_clockwise, color: AppColors.gold, size: 20),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSegmentedTab(),
          Expanded(
            child: _loading
                ? const Center(child: CupertinoActivityIndicator(color: AppColors.gold, radius: 14))
                : _activeTab == 0
                    ? _buildJobsList()
                    : _buildToolsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder, width: 0.6),
        ),
        child: Row(
          children: [
            Expanded(
              child: _tabButton(
                index: 0,
                label: 'Background Crons (${_jobs.length})',
                icon: CupertinoIcons.clock_fill,
              ),
            ),
            Expanded(
              child: _tabButton(
                index: 1,
                label: 'MCP & Extensions (${_tools.length})',
                icon: CupertinoIcons.cube_box_fill,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton({required int index, required String label, required IconData icon}) {
    final isSelected = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: isSelected
              ? Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 0.6)
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

  Widget _buildJobsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: _jobs.length,
      itemBuilder: (context, index) {
        final job = _jobs[index];
        final isRunning = job.status == 'running';
        final isCompleted = job.status == 'completed';

        final Color statusColor = isRunning
            ? AppColors.gold
            : (isCompleted ? const Color(0xFF10B981) : const Color(0xFF38BDF8));

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: GlassDecorations.frostedCard(blur: 16, borderColor: AppColors.glassBorder),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        job.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 0.5),
                    ),
                    child: Text(
                      job.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Jadwal: ${job.schedule ?? "-"} • Tipe: ${job.taskType}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              if (isRunning) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: job.progress,
                    backgroundColor: AppColors.surfaceElevated,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                    minHeight: 5,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Terakhir: ${job.lastRun ?? "-"}',
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                  ),
                  Text(
                    'Berikutnya: ${job.nextRun ?? "-"}',
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: _tools.length,
      itemBuilder: (context, index) {
        final tool = _tools[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: GlassDecorations.frostedCard(blur: 16, borderColor: AppColors.glassBorder),
          child: Row(
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
                child: Icon(
                  tool.category == 'mcp'
                      ? CupertinoIcons.layers_alt_fill
                      : CupertinoIcons.hammer_fill,
                  color: AppColors.gold,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tool.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tool.category.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tool.description,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              CupertinoSwitch(
                value: tool.isEnabled,
                activeColor: AppColors.gold,
                onChanged: (val) async {
                  await MollyLocalDatabase.instance.toggleMcpTool(tool.id, val);
                  setState(() {
                    _tools[index] = ExtensionTool(
                      id: tool.id,
                      name: tool.name,
                      category: tool.category,
                      description: tool.description,
                      isEnabled: val,
                      parameters: tool.parameters,
                    );
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
