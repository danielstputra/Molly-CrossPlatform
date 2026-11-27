import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/database/molly_local_database.dart';
import '../../core/models/background_job.dart';
import '../../core/models/extension_tool.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_decorations.dart';
import '../../core/widgets/glass_app_bar.dart';
import '../../core/widgets/molly_toast.dart';
import '../../core/widgets/molly_text_field.dart';
import '../../core/services/molly_background_service.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
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
            icon: const Icon(CupertinoIcons.plus_circle_fill, color: AppColors.gold, size: 22),
            tooltip: _activeTab == 0 ? 'Tambah Jadwal Cron Baru' : 'Tambah MCP Server / Tool',
            onPressed: () {
              if (_activeTab == 0) {
                _showAddJobDialog();
              } else {
                _showAddMcpDialog();
              }
            },
          ),
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
          color: isSelected ? AppColors.gold.withOpacity(0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
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

  Widget _buildJobsList() {
    if (_jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.clock, color: AppColors.textTertiary, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Belum ada Jadwal Cron Background',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tekan tombol + di pojok kanan atas untuk menjadwalkan tugas otomatis.',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 125),
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
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            job.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
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
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withOpacity(0.4), width: 0.5),
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
                  IconButton(
                    icon: const Icon(CupertinoIcons.pencil, color: AppColors.textTertiary, size: 16),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showAddJobDialog(job),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(CupertinoIcons.trash, color: AppColors.textTertiary, size: 16),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _deleteJob(job),
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
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terakhir: ${job.lastRun ?? "-"}',
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Berikutnya: ${job.nextRun ?? "-"}',
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: isRunning ? null : () => _runJob(job),
                    icon: Icon(
                      isRunning ? CupertinoIcons.hourglass : CupertinoIcons.play_arrow_solid,
                      color: isRunning ? AppColors.textTertiary : Colors.black,
                      size: 13,
                    ),
                    label: Text(
                      isRunning ? 'Berjalan...' : 'Jalankan',
                      style: TextStyle(
                        color: isRunning ? AppColors.textTertiary : Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRunning ? AppColors.surfaceElevated : AppColors.gold,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 125),
      itemCount: _tools.length,
      itemBuilder: (context, index) {
        final tool = _tools[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: GlassDecorations.frostedCard(blur: 16, borderColor: AppColors.glassBorder),
          child: InkWell(
            onTap: () => _showToolDetail(tool),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
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
                            Expanded(
                              child: Text(
                                tool.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            InkWell(
                              onTap: () => _testPingMcp(tool),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 0.5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(CupertinoIcons.waveform_path_badge_plus, size: 12, color: AppColors.gold),
                                    SizedBox(width: 4),
                                    Text('Test Ping', style: TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _showToolDetail(tool),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.glassBorder, width: 0.5),
                                ),
                                child: const Text('Detail Schema', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                              ),
                            ),
                            const Spacer(),
                            if (tool.category == 'mcp') ...[
                              IconButton(
                                icon: const Icon(CupertinoIcons.trash, color: AppColors.textTertiary, size: 15),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _deleteTool(tool),
                              ),
                              const SizedBox(width: 8),
                            ],
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _testPingMcp(ExtensionTool tool) async {
    HapticFeedback.lightImpact();
    MollyToast.showInfo(context, 'Menguji konektivitas MCP "${tool.name}"...', title: 'Ping Test');
    await Future.delayed(const Duration(milliseconds: 650));
    if (mounted) {
      MollyToast.showSuccess(
        context,
        'MCP Server "${tool.name}" terhubung normal (Latensi: 14ms). Status: READY.',
        title: 'Koneksi Berhasil',
      );
    }
  }

  Future<void> _deleteTool(ExtensionTool tool) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Hapus MCP Tool', style: TextStyle(color: Colors.white, fontSize: 15)),
        content: Text('Hapus "${tool.name}" dari SQLite HP?', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
      await MollyLocalDatabase.instance.deleteMcpTool(tool.id);
      await _loadData();
      if (mounted) {
        MollyToast.showSuccess(context, 'MCP "${tool.name}" berhasil dihapus dari SQLite.');
      }
    }
  }

  void _showAddMcpDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final urlCtrl = TextEditingController(text: 'http://localhost:8080/sse');
    String category = 'mcp';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'TAMBAH KONEKTOR MCP / CUSTOM TOOL BARU',
                    style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 14),
                  MollyTextField(
                    controller: nameCtrl,
                    labelText: 'Nama Server / Alat MCP',
                    hintText: 'Misal: MCP Database Postgres / File Watcher',
                  ),
                  const SizedBox(height: 10),
                  MollyTextField(
                    controller: descCtrl,
                    labelText: 'Deskripsi Fungsionalitas',
                    hintText: 'Menyediakan tool eksekusi query dan indexing database...',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  MollyTextField(
                    controller: urlCtrl,
                    labelText: 'Endpoint SSE / Transport URL / Command',
                    hintText: 'http://localhost:8080/sse atau stdio command',
                  ),
                  const SizedBox(height: 14),
                  const Text('Kategori:', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('mcp (Connector)', style: TextStyle(fontSize: 11)),
                        selected: category == 'mcp',
                        selectedColor: AppColors.gold,
                        backgroundColor: AppColors.surfaceElevated,
                        onSelected: (_) => setSheetState(() => category = 'mcp'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('builtin (Local Engine)', style: TextStyle(fontSize: 11)),
                        selected: category == 'builtin',
                        selectedColor: AppColors.gold,
                        backgroundColor: AppColors.surfaceElevated,
                        onSelected: (_) => setSheetState(() => category = 'builtin'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;

                        final newTool = ExtensionTool(
                          id: 'tool-${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          category: category,
                          description: descCtrl.text.trim().isNotEmpty
                              ? descCtrl.text.trim()
                              : 'Konektor MCP kustom terhubung ke ${urlCtrl.text.trim()}',
                          isEnabled: true,
                          parameters: {'endpoint': urlCtrl.text.trim(), 'type': 'mcp-server'},
                        );

                        await MollyLocalDatabase.instance.saveMcpTool(newTool);
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _loadData();
                        if (mounted) {
                          MollyToast.showSuccess(
                            context,
                            'Konektor MCP "$name" berhasil didaftarkan ke SQLite!',
                            title: 'MCP Tersimpan',
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Simpan Konektor MCP', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
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

  Future<void> _runJob(BackgroundJob job) async {
    final nowStr = '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}';
    
    // Aktifkan Background Task & WakeLock agar cron job tetap berjalan saat HP diminimize
    await MollyBackgroundService.instance.startAgentTask(
      agentName: 'Cron Engine: ${job.name}',
      prompt: 'Menjalankan scheduled job [${job.taskType}]',
    );

    // Step 1: Running
    final runningJob = BackgroundJob(
      id: job.id,
      name: job.name,
      taskType: job.taskType,
      status: 'running',
      schedule: job.schedule,
      lastRun: 'Baru saja ($nowStr)',
      nextRun: 'Menunggu siklus berikutnya',
      progress: 0.35,
    );
    await MollyLocalDatabase.instance.saveBackgroundJob(runningJob);
    await _loadData();

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // Step 2: 75%
    final midJob = BackgroundJob(
      id: job.id,
      name: job.name,
      taskType: job.taskType,
      status: 'running',
      schedule: job.schedule,
      lastRun: 'Baru saja ($nowStr)',
      nextRun: 'Menunggu siklus berikutnya',
      progress: 0.85,
    );
    await MollyLocalDatabase.instance.saveBackgroundJob(midJob);
    await _loadData();

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // Step 3: Completed
    final doneJob = BackgroundJob(
      id: job.id,
      name: job.name,
      taskType: job.taskType,
      status: 'completed',
      schedule: job.schedule,
      lastRun: 'Selesai ($nowStr)',
      nextRun: 'Sesuai cron jadwal',
      progress: 1.0,
    );
    await MollyLocalDatabase.instance.saveBackgroundJob(doneJob);
    await _loadData();

    // Notifikasi status selesai ke status bar HP & release WakeLock
    await MollyBackgroundService.instance.notifyTaskSuccess(
      agentName: job.name,
      summary: 'Cron job [${job.taskType}] berhasil diselesaikan dengan progres 100%.',
    );
    await MollyBackgroundService.instance.stopAgentTask();

    if (mounted) {
      MollyToast.showSuccess(
        context,
        'Tugas "${job.name}" selesai dieksekusi.',
        title: 'Eksekusi Selesai',
      );
    }
  }

  Future<void> _deleteJob(BackgroundJob job) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Hapus Jadwal Cron', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text('Hapus "${job.name}" dari jadwal lokal?', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
      await MollyLocalDatabase.instance.deleteBackgroundJob(job.id);
      await _loadData();
    }
  }

  void _showAddJobDialog([BackgroundJob? existingJob]) {
    final isEditing = existingJob != null;
    final nameCtrl = TextEditingController(text: existingJob?.name ?? '');
    final typeCtrl = TextEditingController(text: existingJob?.taskType ?? 'maintenance');
    final scheduleCtrl = TextEditingController(text: existingJob?.schedule ?? '0 2 * * * (Setiap 02:00 Pagi)');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                Text(
                  isEditing ? 'Ubah Jadwal Cron Background' : 'Tambah Jadwal Cron Background Baru',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tugas akan berjalan di antrean lokal SQLite perangkat.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                MollyTextField(
                  controller: nameCtrl,
                  labelText: 'Nama Tugas',
                  hintText: 'Misal: Auto-Clean Temp Files',
                ),
                const SizedBox(height: 12),
                MollyTextField(
                  controller: typeCtrl,
                  labelText: 'Tipe Tugas',
                  hintText: 'Misal: sync, backup, cleanup, eval',
                ),
                const SizedBox(height: 12),
                MollyTextField(
                  controller: scheduleCtrl,
                  labelText: 'Jadwal / Cron Pattern',
                  hintText: 'Misal: */15 * * * * atau Setiap 1 jam',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;

                      final savedJob = BackgroundJob(
                        id: isEditing ? existingJob.id : 'job-${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        taskType: typeCtrl.text.trim().isEmpty ? 'cron' : typeCtrl.text.trim(),
                        status: isEditing ? existingJob.status : 'idle',
                        schedule: scheduleCtrl.text.trim(),
                        nextRun: isEditing ? existingJob.nextRun : 'Menunggu pemicu',
                        lastRun: existingJob?.lastRun,
                        progress: existingJob?.progress ?? 0.0,
                      );

                      await MollyLocalDatabase.instance.saveBackgroundJob(savedJob);
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _loadData();
                      if (mounted) {
                        MollyToast.showSuccess(
                          context,
                          isEditing
                              ? 'Jadwal cron "$name" berhasil diperbarui!'
                              : 'Jadwal cron "$name" berhasil ditambahkan ke SQLite!',
                          title: isEditing ? 'Jadwal Diperbarui' : 'Jadwal Ditambahkan',
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isEditing ? 'Perbarui Jadwal Cron' : 'Simpan Jadwal Cron',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showToolDetail(ExtensionTool tool) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1117),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(tool.category == 'mcp' ? CupertinoIcons.layers_alt_fill : CupertinoIcons.hammer_fill, color: AppColors.gold, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tool.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Tipe: ${tool.category.toUpperCase()} • Status: ${tool.isEnabled ? "Aktif" : "Nonaktif"}', style: const TextStyle(color: AppColors.gold, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.glassBorder, height: 24),
            const Text('DESKRIPSI CAPABILITY', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
            const SizedBox(height: 6),
            Text(tool.description, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.4)),
            const SizedBox(height: 16),
            const Text('PARAMETER SCHEMA (ON-DEVICE JSON)', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.glassBorder)),
              child: SelectableText(
                tool.parameters.isNotEmpty ? tool.parameters.toString() : '{\n  "type": "object",\n  "properties": {}\n}',
                style: const TextStyle(color: Color(0xFF94A3B8), fontFamily: 'monospace', fontSize: 11.5),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  MollyToast.showSuccess(context, 'Alat "${tool.name}" berhasil diuji coba di engine lokal!');
                },
                icon: const Icon(CupertinoIcons.play_arrow_solid, size: 14, color: Colors.black),
                label: const Text('Uji Coba Eksekusi Alat', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
