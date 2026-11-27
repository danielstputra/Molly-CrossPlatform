import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../theme/app_colors.dart';

/// Kartu animasi interaktif yang menampilkan aktivitas pemanggilan alat (tool execution) oleh Agen AI.
class ToolCallCard extends StatefulWidget {
  final ToolInvocation tool;

  const ToolCallCard({super.key, required this.tool});

  @override
  State<ToolCallCard> createState() => _ToolCallCardState();
}

class _ToolCallCardState extends State<ToolCallCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isRunning = widget.tool.status == 'running';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGlass, width: 0.8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isRunning)
                    const CupertinoActivityIndicator(radius: 7, color: AppColors.gold)
                  else
                    const Icon(CupertinoIcons.check_mark_circled_solid, size: 14, color: AppColors.success),
                  const SizedBox(width: 8),
                  const Text(
                    "Alat: ",
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  Flexible(
                    child: Text(
                      widget.tool.toolName,
                      style: const TextStyle(
                        color: AppColors.goldLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const Divider(color: AppColors.borderGlass, height: 16),
                const Text(
                  "Argumen Input:",
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    const JsonEncoder.withIndent('  ').convert(widget.tool.args),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
                if (widget.tool.result != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    "Hasil Eksekusi:",
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.tool.result is String
                          ? widget.tool.result
                          : const JsonEncoder.withIndent('  ').convert(widget.tool.result),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.info),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
