import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/app_update_service.dart';
import '../theme/app_colors.dart';
import '../theme/glass_decorations.dart';
import 'molly_toast.dart';

class AppUpdateDialog extends StatelessWidget {
  final GitHubRelease release;

  const AppUpdateDialog({
    super.key,
    required this.release,
  });

  static Future<void> show(BuildContext context, GitHubRelease release) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AppUpdateDialog(release: release),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 560),
            padding: const EdgeInsets.all(20),
            decoration: GlassDecorations.frostedCard(
              blur: 25,
              borderColor: AppColors.gold.withOpacity(0.4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Icon & Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.rocket_launch_rounded, color: Colors.black, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pembaruan Tersedia! 🚀',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            release.name,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill, color: AppColors.textTertiary, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Version Tag Comparison Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Versi Terpasang', style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                          const SizedBox(height: 1),
                          Text(
                            AppUpdateService.currentTag,
                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_rounded, color: AppColors.gold, size: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Rilis GitHub', style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                          const SizedBox(height: 1),
                          Text(
                            release.tagName,
                            style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Changelog Label & Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Catatan Rilis (Changelog):',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      release.formattedDate,
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Scrollable Markdown Changelog Box
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderGlass),
                    ),
                    child: Markdown(
                      data: release.body.isNotEmpty
                          ? release.body
                          : 'Pembaruan stabilitas, sinkronisasi database, dan peningkatan fitur.',
                      shrinkWrap: true,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                        h1: const TextStyle(color: AppColors.gold, fontSize: 15, fontWeight: FontWeight.bold),
                        h2: const TextStyle(color: AppColors.goldLight, fontSize: 13.5, fontWeight: FontWeight.bold),
                        h3: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                        code: const TextStyle(
                          color: AppColors.goldLight,
                          backgroundColor: Colors.black38,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                        listBullet: const TextStyle(color: AppColors.gold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Download Button (Primary)
                SizedBox(
                  height: 46,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.black,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).pop();
                        MollyToast.showInfo(context, 'Membuka tautan unduhan pembaruan...');
                        await AppUpdateService.instance.launchDownload(release);
                      },
                      icon: const Icon(Icons.download_rounded, size: 20, color: Colors.black),
                      label: const Text(
                        'Unduh Pembaruan Sekarang',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Secondary Row: Buka di GitHub & Tutup
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          await AppUpdateService.instance.launchDownload(release);
                        },
                        icon: const Icon(CupertinoIcons.arrow_up_right, size: 14),
                        label: const Text('Buka GitHub', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textTertiary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Nanti Saja', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
