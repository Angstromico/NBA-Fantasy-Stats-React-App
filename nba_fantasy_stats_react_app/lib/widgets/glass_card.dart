import 'package:flutter/material.dart';

/// Frosted-glass style container — the reusable card wrapper used across
/// screens (mirrors the `.glass-card` CSS class).
///
/// Minimal version for Step 4; Step 6 upgrades this in place with a
/// `BackdropFilter` blur driven by the `GlassTheme` extension.
class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      child: child,
    );
  }
}
