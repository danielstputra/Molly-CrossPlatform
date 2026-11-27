import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/models/chat_message.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/code_block_viewer.dart';
import '../../core/widgets/molly_toast.dart';
import '../../core/widgets/tool_call_card.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onRegenerate;

  const MessageBubble({
    super.key,
    required this.message,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _buildUserBubble(context);
    } else {
      return _buildAssistantBubble(context);
    }
  }

  Widget _buildUserBubble(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: 48, right: 14, top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.goldGlow.withOpacity(0.22),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
          border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 0.9),
          boxShadow: [
            BoxShadow(
              color: AppColors.goldGlow.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: SelectableText(
          message.content,
          style: const TextStyle(
            color: Color(0xFFFEF08A),
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantBubble(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 14, right: 36, top: 4, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface.withOpacity(0.85),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(color: AppColors.borderGlass, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar & Header Molly
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.goldGradient,
                  ),
                  child: const Center(
                    child: Text(
                      "M",
                      style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Molly AI",
                  style: TextStyle(color: AppColors.textGold, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                if (message.isStreaming) ...[
                  const SizedBox(width: 8),
                  const CupertinoActivityIndicator(radius: 6, color: AppColors.gold),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Tool Invocations
            if (message.toolCalls.isNotEmpty) ...[
              for (final tool in message.toolCalls) ToolCallCard(tool: tool),
              const SizedBox(height: 6),
            ],

            // Konten Markdown & Code Blocks
            if (message.content.isNotEmpty) _buildContentBody(message.content),

            // Footer info & aksi salin
            if (!message.isStreaming && message.content.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(CupertinoIcons.checkmark_seal_fill, size: 11, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'On-Device SQLite Engine',
                            style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onRegenerate != null) ...[
                        InkWell(
                          onTap: onRegenerate,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(CupertinoIcons.arrow_2_circlepath, size: 12, color: AppColors.textSecondary),
                                SizedBox(width: 4),
                                Text(
                                  'Buat Ulang',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: message.content));
                          MollyToast.showSuccess(context, 'Jawaban Molly berhasil disalin!');
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(CupertinoIcons.doc_on_clipboard, size: 12, color: AppColors.gold),
                              SizedBox(width: 4),
                              Text(
                                'Salin',
                                style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContentBody(String content) {
    // Membagi teks menjadi segmen biasa dan blok kode ```language ... ```
    final List<Widget> widgets = [];
    final codeBlockRegex = RegExp(r'```([a-zA-Z0-9_\-\+]*)\n([\s\S]*?)```');
    int lastEnd = 0;

    for (final match in codeBlockRegex.allMatches(content)) {
      if (match.start > lastEnd) {
        final textPart = content.substring(lastEnd, match.start).trim();
        if (textPart.isNotEmpty) {
          widgets.add(_buildMarkdownText(textPart));
        }
      }

      final lang = match.group(1)?.trim();
      final code = match.group(2)?.trim() ?? '';
      widgets.add(CodeBlockViewer(code: code, language: lang?.isNotEmpty == true ? lang : null));

      lastEnd = match.end;
    }

    if (lastEnd < content.length) {
      final remaining = content.substring(lastEnd).trim();
      if (remaining.isNotEmpty) {
        widgets.add(_buildMarkdownText(remaining));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  Widget _buildMarkdownText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: MarkdownBody(
        data: text,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
          h1: const TextStyle(color: AppColors.goldLight, fontSize: 17, fontWeight: FontWeight.bold),
          h2: const TextStyle(color: AppColors.gold, fontSize: 15, fontWeight: FontWeight.bold),
          h3: const TextStyle(color: AppColors.textGold, fontSize: 14, fontWeight: FontWeight.w600),
          code: const TextStyle(
            color: Color(0xFFFDE047),
            backgroundColor: Color(0x33000000),
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
