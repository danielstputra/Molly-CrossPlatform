import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Standar Inputan Teks Molly berdesain Anti-UI Slop.
/// Menjamin posisi rapi, batas teks aman di dalam box, dan visual kontras tinggi.
class MollyTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final int maxLines;
  final int minLines;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? helperText;
  final TextStyle? style;

  const MollyTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.maxLines = 1,
    this.minLines = 1,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.helperText,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              labelText!,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorder, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              minLines: minLines,
              obscureText: obscureText,
              keyboardType: keyboardType,
              readOnly: readOnly,
              onTap: onTap,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: style ?? const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.transparent,
                hintText: hintText,
                hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12.5),
                prefixIcon: prefixIcon,
                suffixIcon: suffixIcon,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.gold, width: 1.2),
                ),
                enabledBorder: InputBorder.none,
              ),
            ),
          ),
        ),
        if (helperText != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 4),
            child: Text(
              helperText!,
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 10.5),
            ),
          ),
        ],
      ],
    );
  }
}

