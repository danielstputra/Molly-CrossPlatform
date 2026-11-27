import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/models/chat_message.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/code_block_viewer.dart';
import '../../core/widgets/tool_call_card.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

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
        margin: const EdgeInsets.only(left: 48, right: 16, top: 6, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          message.content,
          style: const TextStyle(
            color: Color(0xFFFEF08A),
            fontSize: 14.5,
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
        margin: const EdgeInsets.only(left: 16, right: 48, top: 6, bottom: 6),
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
            // Avatar & Nama Molly
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
                    child: Text("M", style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w800)),
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

            // Konten Markdown
            if (message.content.isNotEmpty)
              MarkdownBody(
                data: message.content,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: AppColors.textPrimary, fontSize: 14.5, height: 1.5),
                  h1: const TextStyle(color: AppColors.goldLight, fontSize: 18, fontWeight: FontWeight.bold),
                  h2: const TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.bold),
                  h3: const TextStyle(color: AppColors.textGold, fontSize: 15, fontWeight: FontWeight.w600),
                  code: const TextStyle(color: Color(0xFFFDE047), backgroundColor: Color(0x33000000)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
