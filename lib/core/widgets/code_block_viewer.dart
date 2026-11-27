import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import 'molly_toast.dart';

/// Kotak kode bergaya jendela macOS Terminal dengan titik kontrol (Red, Yellow, Green),
/// label bahasa, dan tombol salin instan satu ketukan.
class CodeBlockViewer extends StatelessWidget {
  final String code;
  final String? language;
  final String? fileName;

  const CodeBlockViewer({
    super.key,
    required this.code,
    this.language,
    this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF07090E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGlass, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Jendela macOS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0F121A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                bottom: BorderSide(color: AppColors.borderGlass, width: 0.6),
              ),
            ),
            child: Row(
              children: [
                // Titik Window macOS (Close, Minimize, Maximize)
                Row(
                  children: [
                    Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFFFF5F56), shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFF27C93F), shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(width: 12),
                Text(
                  (language ?? 'text').toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    MollyToast.showSuccess(context, 'Kode berhasil disalin ke clipboard!');
                  },
                  child: Row(
                    children: const [
                      Icon(CupertinoIcons.doc_on_clipboard, size: 13, color: AppColors.gold),
                      SizedBox(width: 4),
                      Text("Salin", style: TextStyle(color: AppColors.gold, fontSize: 11.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Isi Kode
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                color: Color(0xFFE2E8F0),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
