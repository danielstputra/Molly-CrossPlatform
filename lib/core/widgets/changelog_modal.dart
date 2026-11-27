import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/app_update_service.dart';
import '../theme/app_colors.dart';
import '../theme/glass_decorations.dart';
import 'molly_toast.dart';

class ChangelogModal extends StatefulWidget {
  const ChangelogModal({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ChangelogModal(),
    );
  }

  @override
  State<ChangelogModal> createState() => _ChangelogModalState();
}

class _ChangelogModalState extends State<ChangelogModal> {
  bool _loading = true;
  String? _error;
  List<GitHubRelease> _releases = [];

  @override
  void initState() {
    super.initState();
    _loadChangelog();
  }

  Future<void> _loadChangelog() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await AppUpdateService.instance.fetchChangelogHistory(limit: 15);
      if (mounted) {
        setState(() {
          _releases = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset > 0 ? bottomInset + 12 : 20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.gold.withOpacity(0.35), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(CupertinoIcons.doc_text_fill, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Riwayat Rilis & Changelog GitHub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Semua pembaruan resmi dari repository GitHub',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.arrow_clockwise, color: AppColors.gold, size: 18),
                tooltip: 'Segarkan',
                onPressed: _loadChangelog,
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.xmark_circle_fill, color: AppColors.textTertiary, size: 22),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoActivityIndicator(radius: 14, color: AppColors.gold),
            SizedBox(height: 12),
            Text(
              'Memuat changelog dari GitHub Releases...',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.exclamationmark_triangle, color: AppColors.warning, size: 36),
              const SizedBox(height: 10),
              const Text(
                'Gagal Mengambil Changelog',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _loadChangelog,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),
      );
    }

    if (_releases.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada catatan rilis di GitHub.',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
      );
    }

    return ListView.separated(
      itemCount: _releases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final rel = _releases[index];
        final isCurrent = rel.tagName.toLowerCase().trim() == AppUpdateService.currentTag.toLowerCase().trim();

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: GlassDecorations.frostedCard(
            blur: 15,
            borderColor: isCurrent ? AppColors.gold.withOpacity(0.5) : AppColors.borderGlass,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Tag & Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        rel.tagName,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0x22EAB308),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.gold, width: 0.6),
                          ),
                          child: const Text(
                            'TERPASANG',
                            style: TextStyle(color: AppColors.gold, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    rel.formattedDate,
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Title
              Text(
                rel.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              // Changelog Markdown body
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: SingleChildScrollView(
                  child: MarkdownBody(
                    data: rel.body,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.4),
                      h1: const TextStyle(color: AppColors.gold, fontSize: 13.5, fontWeight: FontWeight.bold),
                      h2: const TextStyle(color: AppColors.goldLight, fontSize: 12.5, fontWeight: FontWeight.bold),
                      h3: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      code: const TextStyle(color: AppColors.goldLight, backgroundColor: Colors.black38, fontSize: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Action buttons (Unduh APK / IPA / Buka GitHub)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (rel.apkDownloadUrl != null)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        MollyToast.showInfo(context, 'Mengunduh APK dari GitHub...');
                        await AppUpdateService.instance.launchDownload(rel);
                      },
                      icon: const Icon(Icons.android, size: 14),
                      label: const Text('Unduh APK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  if (rel.ipaDownloadUrl != null)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.12),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        MollyToast.showInfo(context, 'Mengunduh IPA dari GitHub...');
                        await AppUpdateService.instance.launchDownload(rel);
                      },
                      icon: const Icon(CupertinoIcons.applelogo, size: 14),
                      label: const Text('Unduh IPA', style: TextStyle(fontSize: 11)),
                    ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      await AppUpdateService.instance.launchDownload(rel);
                    },
                    icon: const Icon(CupertinoIcons.arrow_up_right, size: 12),
                    label: const Text('Halaman Rilis', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
