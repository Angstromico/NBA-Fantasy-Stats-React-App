import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats_react_app/theme/app_theme.dart';

/// Frosted-glass style container — the reusable card wrapper used across
/// screens (mirrors the `.glass-card` CSS class in `src/App.css`):
/// semi-transparent fill, `BackdropFilter` blur, 1px border, and the
/// `--glass-shadow` drop shadow.
///
/// All visual constants come from the `GlassTheme` extension so light and
/// dark modes render their own palette (Step 6 of FLUTTER_PLAN.md).
class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTheme>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(glass.borderRadius),
        boxShadow: [
          BoxShadow(
            color: glass.shadowColor,
            offset: glass.shadowOffset,
            blurRadius: glass.shadowBlurRadius,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(glass.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: glass.blurSigma,
            sigmaY: glass.blurSigma,
          ),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: glass.glassColor,
              borderRadius: BorderRadius.circular(glass.borderRadius),
              border: Border.all(color: glass.glassBorder),
            ),
            // Local transparent Material so tiles/ink inside the glass card
            // paint correctly instead of asserting against the card fill.
            child: Material(type: MaterialType.transparency, child: child),
          ),
        ),
      ),
    );
  }
}
