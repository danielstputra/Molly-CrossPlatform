import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/database/molly_local_database.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_decorations.dart';
import '../../core/widgets/glass_app_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _metrics;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await MollyLocalDatabase.instance.computeRealTelemetry();
    if (mounted) {
      setState(() {
        _metrics = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Molly Telemetry & Dashboard',
        showBackButton: false,
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadData,
            icon: _loading
                ? const CupertinoActivityIndicator(color: AppColors.gold)
                : const Icon(CupertinoIcons.arrow_clockwise, color: AppColors.gold, size: 20),
            tooltip: 'Segarkan Data',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final int metricCols = width < 640 ? 1 : (width < 1024 ? 2 : 4);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroBanner(),
                const SizedBox(height: 24),

                // Metrics Section Heading
                const Text(
                  'METRIK SISTEM REAL-TIME',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                // Fluid Multi-Column Grid
                _buildMetricsGrid(metricCols),
                const SizedBox(height: 28),

                // Model Providers Telemetry
                const Text(
                  'STATUS PROVIDER MODEL & LATENSI',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                _buildProvidersCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.goldGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.4),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const Icon(CupertinoIcons.speedometer, color: Colors.black, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Molly AI Studio Control Plane',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Memantau konsumsi token, performa orkestrasi multi-agen, dan throughput model.',
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.9),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildMetricsGrid(int columns) {
    final nf = NumberFormat.compact();
    final tokens = _metrics?['total_tokens'] ?? 0;
    final agents = _metrics?['active_agents'] ?? 0;
    final latency = _metrics?['average_latency_ms'] ?? 0;
    final uptime = _metrics?['uptime_percent'] ?? 0.0;

    final items = [
      _MetricData(
        title: 'Total Token Terpakai',
        value: nf.format(tokens),
        sub: 'Bulan Berjalan',
        icon: CupertinoIcons.chart_bar_alt_fill,
        glowColor: AppColors.gold,
      ),
      _MetricData(
        title: 'Agen Presets Aktif',
        value: '$agents',
        sub: 'Presensi Engine',
        icon: CupertinoIcons.person_3_fill,
        glowColor: const Color(0xFF38BDF8),
      ),
      _MetricData(
        title: 'Rata-Rata Latensi',
        value: latency > 0 ? '${latency}ms' : '0ms',
        sub: 'TTFT (Time-to-First-Token)',
        icon: CupertinoIcons.bolt_fill,
        glowColor: const Color(0xFFF59E0B),
      ),
      _MetricData(
        title: 'System Health / Uptime',
        value: uptime > 0 ? '$uptime%' : '0%',
        sub: 'Engine Telemetri Aktif',
        icon: CupertinoIcons.checkmark_shield_fill,
        glowColor: const Color(0xFF10B981),
      ),
    ];

    if (columns == 1) {
      return Column(
        children: items.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMetricCard(m),
        )).toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.8,
      ),
      itemBuilder: (context, index) => _buildMetricCard(items[index]),
    );
  }

  Widget _buildMetricCard(_MetricData m) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecorations.frostedCard(
        blur: 16,
        borderColor: AppColors.glassBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  m.title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(m.icon, color: m.glowColor, size: 18),
            ],
          ),
          Text(
            m.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            m.sub,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProvidersCard() {
    final Map<String, dynamic> providers = _metrics?['providers'] is Map<String, dynamic>
        ? _metrics!['providers']
        : <String, dynamic>{};

    if (providers.isEmpty) {
      return Container(
        decoration: GlassDecorations.frostedCard(blur: 20, borderColor: AppColors.glassBorder),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: const [
              Icon(CupertinoIcons.antenna_radiowaves_left_right, color: AppColors.textTertiary, size: 28),
              SizedBox(height: 8),
              Text(
                'Belum ada data provider yang diterima dari engine.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: GlassDecorations.frostedCard(blur: 20, borderColor: AppColors.glassBorder),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: providers.entries.map((entry) {
          final name = entry.key;
          final status = entry.value['status'] ?? 'online';
          final latency = entry.value['latency'] ?? '300ms';
          final isOnline = status == 'online';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.glassBorder,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    latency,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MetricData {
  final String title;
  final String value;
  final String sub;
  final IconData icon;
  final Color glowColor;

  const _MetricData({
    required this.title,
    required this.value,
    required this.sub,
    required this.icon,
    required this.glowColor,
  });
}
