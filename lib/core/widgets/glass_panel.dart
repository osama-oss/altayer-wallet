import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/bank_sync_colors.dart';

/// Crisp white surface card matching the UBS / uff electric-indigo identity:
/// solid surface, hairline border, soft shadow (no frosted blur).
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = AppColors.radiusMd,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class MeshBackground extends StatelessWidget {
  const MeshBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(color: colors.background),
        ),
        Positioned(
          top: -80,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.secondary.withValues(alpha: 0.05),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          right: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.secondaryContainer.withValues(alpha: 0.05),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
