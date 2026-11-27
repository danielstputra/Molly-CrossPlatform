import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/abridge_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_decorations.dart';
import '../../core/widgets/glass_app_bar.dart';

class ABridgeScreen extends StatefulWidget {
  const ABridgeScreen({super.key});

  @override
  State<ABridgeScreen> createState() => _ABridgeScreenState();
}

class _ABridgeScreenState extends State<ABridgeScreen> {
  final _abridge = ABridgeService.instance;
  Map<String, dynamic>? _deviceInfo;
  bool _loading = false;
  final TextEditingController _packageController =
      TextEditingController(text: 'com.android.settings');

  @override
  void initState() {
    super.initState();
    _fetchInfo();
  }

  Future<void> _fetchInfo() async {
    setState(() => _loading = true);
    final info = await _abridge.getDeviceInfo();
    if (mounted) {
      setState(() {
        _deviceInfo = info;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'aBridge Device Controller',
        showBackButton: false,
        actions: [
          IconButton(
            onPressed: _loading ? null : _fetchInfo,
            icon: _loading
                ? const CupertinoActivityIndicator(color: AppColors.gold)
                : const Icon(CupertinoIcons.arrow_clockwise, color: AppColors.gold, size: 20),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeviceStatusCard(),
            const SizedBox(height: 16),
            _buildActionTestpad(),
            const SizedBox(height: 16),
            _buildMcpExecutionLogs(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceStatusCard() {
    final model = _deviceInfo?['model'] ?? 'Mendeteksi...';
    final mfr = _deviceInfo?['manufacturer'] ?? '-';
    final release = _deviceInfo?['release'] ?? '-';
    final platform = _deviceInfo?['platform'] ?? 'Android';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: GlassDecorations.frostedCard(blur: 20, borderColor: AppColors.gold.withOpacity(0.35)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 0.8),
                    ),
                    child: const Icon(CupertinoIcons.device_phone_portrait, color: AppColors.gold, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$mfr • $platform $release',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4), width: 0.6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircleAvatar(radius: 3.5, backgroundColor: Color(0xFF10B981)),
                    SizedBox(width: 6),
                    Text(
                      'ONLINE',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.glassBorder, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _specCol('Bridge Mode', 'In-Process MCP'),
                _specCol('Latensi', '< 1 ms (Lokal)'),
                _specCol('Aksesibilitas', 'Aktif & Siap'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _specCol(String title, String val) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
        const SizedBox(height: 3),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildActionTestpad() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: GlassDecorations.frostedCard(blur: 16, borderColor: AppColors.glassBorder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(CupertinoIcons.play_circle_fill, color: AppColors.gold, size: 18),
              SizedBox(width: 8),
              Text(
                'Testpad Otomasi Perangkat Langsung',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Uji kemampuan remote gesture, haptic, dan app launch yang dapat dieksekusi oleh Agen AI Molly.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          // Input App
          TextField(
            controller: _packageController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Package Name Target Android',
              labelStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
              suffixIcon: IconButton(
                icon: const Icon(CupertinoIcons.arrow_up_right_circle_fill, color: AppColors.gold, size: 20),
                onPressed: () {
                  final pkg = _packageController.text.trim();
                  if (pkg.isNotEmpty) _abridge.openApp(pkg);
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _quickAppChip('Settings', 'com.android.settings'),
                _quickAppChip('Kalkulator', 'com.google.android.calculator'),
                _quickAppChip('Chrome', 'com.android.chrome'),
                _quickAppChip('YouTube', 'com.google.android.youtube'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Action Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _actionBtn(
                icon: CupertinoIcons.waveform,
                label: 'Getar Haptik',
                onPressed: () => _abridge.vibrate(durationMs: 120),
              ),
              _actionBtn(
                icon: CupertinoIcons.hand_point_left_fill,
                label: 'Simulasi Tap (500, 1000)',
                onPressed: () => _abridge.executeMcpTool('abridge_tap', {'x': 500, 'y': 1000}),
              ),
              _actionBtn(
                icon: CupertinoIcons.arrow_up_down,
                label: 'Simulasi Swipe',
                onPressed: () => _abridge.executeMcpTool('abridge_swipe', {
                  'from_x': 500,
                  'from_y': 1500,
                  'to_x': 500,
                  'to_y': 500,
                }),
              ),
              _actionBtn(
                icon: CupertinoIcons.camera_fill,
                label: 'Frame Viewport',
                onPressed: () => _abridge.executeMcpTool('abridge_screenshot', {}),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAppChip(String label, String pkg) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        backgroundColor: AppColors.surfaceElevated,
        side: BorderSide(color: AppColors.glassBorder, width: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        onPressed: () {
          _packageController.text = pkg;
          _abridge.openApp(pkg);
        },
      ),
    );
  }

  Widget _actionBtn({required IconData icon, required String label, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.black, size: 13),
      label: Text(label, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    );
  }

  Widget _buildMcpExecutionLogs() {
    final df = DateFormat('HH:mm:ss');

    return StreamBuilder<List<ABridgeLogEntry>>(
      stream: _abridge.logsStream,
      initialData: _abridge.currentLogs,
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: GlassDecorations.frostedCard(blur: 16, borderColor: AppColors.glassBorder),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(CupertinoIcons.list_bullet_indent, color: AppColors.gold, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Log Eksekusi MCP aBridge Live',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  Text(
                    '${logs.length} Event',
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (logs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  child: const Text(
                    'Belum ada perintah aBridge yang dieksekusi. Tekan tombol aksi di atas untuk memulai.',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length > 8 ? 8 : logs.length,
                  separatorBuilder: (_, __) => const Divider(color: AppColors.glassBorder, height: 16),
                  itemBuilder: (context, idx) {
                    final log = logs[idx];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: log.isSuccess ? const Color(0xFF10B981).withOpacity(0.15) : Colors.redAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            log.tool,
                            style: TextStyle(
                              color: log.isSuccess ? const Color(0xFF10B981) : Colors.redAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            log.summary,
                            style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          df.format(log.timestamp),
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 10),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
