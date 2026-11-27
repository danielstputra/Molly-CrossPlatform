import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Utilitas dekorasi Glassmorphism (Frosted Glass) ala iOS / macOS untuk kartu, appbar, dan panel melayang.
class GlassDecorations {
  /// Membungkus widget anak dengan efek blur kaca (BackdropFilter) dan border halus ala Apple HIG.
  static Widget frostedContainer({
    required Widget child,
    double blur = 18.0,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    Border? border,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.bgGlass,
              borderRadius: radius,
              border: border ?? Border.all(color: AppColors.borderGlass, width: 0.8),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Kartu mewah dengan aksen border emas halus dan efek elevasi ambient.
  static BoxDecoration goldCardDecoration({double radius = 16.0}) {
    return BoxDecoration(
      color: AppColors.bgSurface.withOpacity(0.8),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.borderGold, width: 1.0),
      boxShadow: [
        BoxShadow(
          color: AppColors.goldGlow.withOpacity(0.08),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
