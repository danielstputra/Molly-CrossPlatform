import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Standar Inputan Teks Molly berdesain Anti-UI Slop.
/// Menjamin posisi rapi, batas teks aman di dalam box, dan visual kontras tinggi.
class MollyTextField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
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
    this.focusNode,
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
  State<MollyTextField> createState() => _MollyTextFieldState();
}

class _MollyTextFieldState extends State<MollyTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              widget.labelText!,
              style: TextStyle(
                color: _isFocused ? AppColors.gold : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused ? AppColors.gold : AppColors.glassBorder,
              width: _isFocused ? 1.2 : 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              if (_isFocused)
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              maxLines: widget.maxLines,
              minLines: widget.minLines,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              readOnly: widget.readOnly,
              onTap: widget.onTap,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              style: widget.style ?? const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.transparent,
                hintText: widget.hintText,
                hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12.5),
                prefixIcon: widget.prefixIcon,
                suffixIcon: widget.suffixIcon,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
              ),
            ),
          ),
        ),
        if (widget.helperText != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 4),
            child: Text(
              widget.helperText!,
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 10.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
