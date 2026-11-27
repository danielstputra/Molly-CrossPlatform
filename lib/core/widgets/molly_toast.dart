import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

enum ToastType {
  success,
  error,
  failed,
  warning,
  info,
}

/// Unified Toast & Notification System berstandar Anti-UI Slop.
/// Menjamin teks 100% terlihat jelas, kontras tinggi, dengan ikon status dan getaran haptic.
class MollyToast {
  static void showSuccess(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title ?? 'Berhasil', type: ToastType.success);
  }

  static void showError(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title ?? 'Terjadi Kesalahan', type: ToastType.error);
  }

  static void showFailed(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title ?? 'Gagal', type: ToastType.failed);
  }

  static void showWarning(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title ?? 'Peringatan', type: ToastType.warning);
  }

  static void showInfo(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title ?? 'Informasi', type: ToastType.info);
  }

  static void show(
    BuildContext context, {
    required String message,
    required String title,
    required ToastType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Berikan haptic feedback sesuai jenis toast
    if (type == ToastType.error || type == ToastType.failed) {
      HapticFeedback.heavyImpact();
    } else if (type == ToastType.warning) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    Color accentColor;
    Color bgColor;
    IconData icon;

    switch (type) {
      case ToastType.success:
        accentColor = const Color(0xFF10B981); // Emerald
        bgColor = const Color(0xFF062E1E);
        icon = CupertinoIcons.checkmark_circle_fill;
        break;
      case ToastType.error:
      case ToastType.failed:
        accentColor = const Color(0xFFEF4444); // Coral Red
        bgColor = const Color(0xFF330D0D);
        icon = CupertinoIcons.exclamationmark_circle_fill;
        break;
      case ToastType.warning:
        accentColor = const Color(0xFFF59E0B); // Amber
        bgColor = const Color(0xFF332005);
        icon = CupertinoIcons.exclamationmark_triangle_fill;
        break;
      case ToastType.info:
        accentColor = const Color(0xFF38BDF8); // Sky Blue
        bgColor = const Color(0xFF08273D);
        icon = CupertinoIcons.info_circle_fill;
        break;
    }

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom > 0
        ? MediaQuery.of(context).viewInsets.bottom + 12
        : (MediaQuery.of(context).padding.bottom + 85);

    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          left: 14,
          right: 14,
          bottom: bottomPadding,
        ),
        padding: EdgeInsets.zero,
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentColor.withOpacity(0.6), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: accentColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.18),
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor.withOpacity(0.4), width: 0.8),
                    ),
                    child: Center(
                      child: Icon(icon, color: accentColor, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.toUpperCase(),
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

