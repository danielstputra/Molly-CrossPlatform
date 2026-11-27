import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_decorations.dart';
import '../../core/widgets/frosted_bottom_bar.dart';
import '../agents/agents_screen.dart';
import '../abridge/abridge_screen.dart';
import '../chat/chat_screen.dart';
import '../code_studio/code_studio_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../jobs/jobs_screen.dart';
import '../knowledge/knowledge_screen.dart';
import '../settings/settings_screen.dart';
import '../workspace/workspace_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const ChatScreen(),
    AgentsScreen(
      onSelectAgent: (agent) {
        setState(() => _currentIndex = 0);
      },
    ),
    const CodeStudioScreen(),
    const KnowledgeScreen(),
    const WorkspaceScreen(),
    const JobsScreen(),
    const ABridgeScreen(),
    const DashboardScreen(),
    const SettingsScreen(),
  ];

  final List<_NavMeta> _navMetas = const [
    _NavMeta(
      index: 0,
      label: 'Chat & Agen',
      icon: CupertinoIcons.chat_bubble_2,
      activeIcon: CupertinoIcons.chat_bubble_2_fill,
    ),
    _NavMeta(
      index: 1,
      label: 'Katalog Agen & Skill',
      icon: CupertinoIcons.person_3,
      activeIcon: CupertinoIcons.person_3_fill,
    ),
    _NavMeta(
      index: 2,
      label: 'Molly Code Studio',
      icon: CupertinoIcons.hammer,
      activeIcon: CupertinoIcons.hammer_fill,
    ),
    _NavMeta(
      index: 3,
      label: 'Knowledge & RAG',
      icon: CupertinoIcons.doc_text,
      activeIcon: CupertinoIcons.doc_text_fill,
    ),
    _NavMeta(
      index: 4,
      label: 'Personal Space',
      icon: CupertinoIcons.folder,
      activeIcon: CupertinoIcons.folder_fill,
    ),
    _NavMeta(
      index: 5,
      label: 'Jobs & MCP Registry',
      icon: CupertinoIcons.cube_box,
      activeIcon: CupertinoIcons.cube_box_fill,
    ),
    _NavMeta(
      index: 6,
      label: 'aBridge Controller',
      icon: CupertinoIcons.device_phone_portrait,
      activeIcon: CupertinoIcons.device_phone_portrait,
    ),
    _NavMeta(
      index: 7,
      label: 'Telemetri Dashboard',
      icon: CupertinoIcons.speedometer,
      activeIcon: CupertinoIcons.speedometer,
    ),
    _NavMeta(
      index: 8,
      label: 'Pengaturan Engine',
      icon: CupertinoIcons.gear_alt,
      activeIcon: CupertinoIcons.gear_alt_fill,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 850;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                _buildMacSidebar(),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile Layout (iOS & Android) with Floating Glass Bottom Bar
        final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
        return Scaffold(
          backgroundColor: AppColors.background,
          extendBody: true,
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: isKeyboardOpen
              ? null
              : FrostedBottomBar(
                  currentIndex: _currentIndex >= 4 ? 4 : _currentIndex,
                  items: [
                    const FrostedNavItem(index: 0, icon: CupertinoIcons.chat_bubble_2_fill, label: 'Chat'),
                    const FrostedNavItem(index: 1, icon: CupertinoIcons.person_3_fill, label: 'Agen'),
                    const FrostedNavItem(index: 2, icon: CupertinoIcons.hammer_fill, label: 'Code'),
                    const FrostedNavItem(index: 3, icon: CupertinoIcons.doc_text_fill, label: 'RAG'),
                    FrostedNavItem(
                      index: 4,
                      icon: CupertinoIcons.square_grid_2x2_fill,
                      label: _currentIndex > 3 ? _navMetas[_currentIndex].label.split(' ').first : 'Modul',
                    ),
                  ],
                  onTap: (index) {
                    if (index == 4) {
                      _showMobileMoreSheet();
                    } else {
                      setState(() => _currentIndex = index);
                    }
                  },
                ),
        );
      },
    );
  }

  void _showMobileMoreSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'SEMUA FITUR & MODUL MOLLY',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _navMetas.map((meta) {
                  final isCurrent = _currentIndex == meta.index;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = meta.index);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: (MediaQuery.of(context).size.width - 60) / 2,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.gold.withOpacity(0.16)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrent
                              ? AppColors.gold.withOpacity(0.45)
                              : AppColors.glassBorder,
                          width: 0.6,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCurrent ? meta.activeIcon : meta.icon,
                            color: isCurrent ? AppColors.gold : AppColors.textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              meta.label,
                              style: TextStyle(
                                color: isCurrent ? Colors.white : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Apple macOS Style Frosted Glass Sidebar for Desktop / iPad
  Widget _buildMacSidebar() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.75),
        border: const Border(
          right: BorderSide(
            color: AppColors.glassBorder,
            width: 1,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // macOS Window Controls (Traffic Lights)
                Padding(
                  padding: const EdgeInsets.only(left: 18, top: 16, bottom: 16),
                  child: Row(
                    children: [
                      _macTrafficDot(const Color(0xFFFF5F56)),
                      const SizedBox(width: 8),
                      _macTrafficDot(const Color(0xFFFFBD2E)),
                      const SizedBox(width: 8),
                      _macTrafficDot(const Color(0xFF27C93F)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.gold.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: const Text(
                          'Molly HIG',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],
                  ),
                ),

                // App Brand
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.goldGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withOpacity(0.35),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.sparkles,
                          color: Colors.black,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Molly AI Studio',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Enterprise Standalone',
                            style: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: AppColors.glassBorder, height: 1),
                ),
                const SizedBox(height: 10),

                // Navigation Items List
                Expanded(
                  child: ListView.builder(
                    itemCount: _navMetas.length,
                    itemBuilder: (context, index) {
                      final meta = _navMetas[index];
                      final isSelected = _currentIndex == meta.index;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        child: InkWell(
                          onTap: () {
                            setState(() => _currentIndex = meta.index);
                          },
                          borderRadius: BorderRadius.circular(9),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.gold.withOpacity(0.16)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              border: isSelected
                                  ? Border.all(
                                      color: AppColors.gold.withOpacity(0.35),
                                      width: 0.8,
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? meta.activeIcon : meta.icon,
                                  size: 17,
                                  color: isSelected ? AppColors.gold : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    meta.label,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
                                      fontSize: 12.5,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Server Status Footer
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: GlassDecorations.frostedCard(
                      blur: 10,
                      borderColor: AppColors.glassBorder,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF10B981),
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(
                              begin: 0.4,
                              end: 1.0,
                              duration: 1200.ms,
                            ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Engine SQLite Lokal',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Text(
                                'molly_standalone_v2.db • Mandiri',
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 9,
                                  fontFamily: 'monospace',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _macTrafficDot(Color color) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black.withOpacity(0.2),
          width: 0.5,
        ),
      ),
    );
  }
}

class _NavMeta {
  final int index;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavMeta({
    required this.index,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
