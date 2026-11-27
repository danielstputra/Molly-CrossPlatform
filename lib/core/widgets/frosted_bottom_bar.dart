import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class FrostedNavItem {
  final int index;
  final IconData icon;
  final String label;

  const FrostedNavItem({
    required this.index,
    required this.icon,
    required this.label,
  });
}

/// Floating Frosted Glass Bottom Navigation Bar khas iOS / iPadOS berstandar Anti-UI Slop.
class FrostedBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<FrostedNavItem> items;

  const FrostedBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      margin: EdgeInsets.only(
        left: 14,
        right: 14,
        bottom: bottomInset > 0 ? bottomInset + 6 : 14,
      ),
      height: 60,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.85),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.glassBorder, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: items.map((item) => _buildNavItem(item)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(FrostedNavItem item) {
    final isSelected = currentIndex == item.index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(item.index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withOpacity(0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: AppColors.gold.withOpacity(0.35), width: 0.6)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 18,
              color: isSelected ? AppColors.gold : AppColors.textTertiary,
            ),
            if (isSelected) ...[
              const SizedBox(width: 5),
              Text(
                item.label,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
