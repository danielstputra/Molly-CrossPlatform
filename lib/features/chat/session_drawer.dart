import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/session.dart';
import '../../core/theme/app_colors.dart';

/// Drawer sesi bergaya bilah samping (Sidebar) iPadOS / macOS dengan efek kaca frosted blur.
class SessionDrawer extends StatelessWidget {
  final List<ChatSession> sessions;
  final String currentSessionId;
  final Function(String) onSelectSession;
  final VoidCallback onNewSession;
  final Function(String)? onDeleteSession;

  const SessionDrawer({
    super.key,
    required this.sessions,
    required this.currentSessionId,
    required this.onSelectSession,
    required this.onNewSession,
    this.onDeleteSession,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            color: AppColors.bgPrimary.withOpacity(0.85),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Drawer
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Riwayat Percakapan",
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(CupertinoIcons.square_pencil, color: AppColors.gold, size: 20),
                          tooltip: "Sesi Baru",
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                            onNewSession();
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppColors.borderGlass, height: 1),

                  // Daftar Sesi
                  Expanded(
                    child: sessions.isEmpty
                        ? const Center(
                            child: Text(
                              "Belum ada riwayat percakapan.",
                              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: sessions.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 2),
                            itemBuilder: (context, index) {
                              final session = sessions[index];
                              final isSelected = session.id == currentSessionId;

                              return ListTile(
                                dense: true,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                selected: isSelected,
                                selectedTileColor: AppColors.goldGlow.withOpacity(0.18),
                                leading: Icon(
                                  CupertinoIcons.chat_bubble_fill,
                                  size: 16,
                                  color: isSelected ? AppColors.gold : AppColors.textMuted,
                                ),
                                title: Text(
                                  session.title,
                                  style: TextStyle(
                                    color: isSelected ? AppColors.goldLight : AppColors.textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: onDeleteSession != null && sessions.length > 1
                                    ? IconButton(
                                        icon: const Icon(CupertinoIcons.trash, size: 14, color: AppColors.textTertiary),
                                        onPressed: () {
                                          HapticFeedback.mediumImpact();
                                          onDeleteSession!(session.id);
                                        },
                                      )
                                    : null,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.pop(context);
                                  onSelectSession(session.id);
                                },
                              );
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
}
