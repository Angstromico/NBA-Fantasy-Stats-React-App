import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats_react_app/theme/app_theme.dart';
import 'package:nba_fantasy_stats_react_app/widgets/glass_card.dart';

/// Severity of a confirmation — drives the accent color, icon, and details
/// tint. Mirrors the `tone` prop of `ConfirmationModal.tsx`
/// (`'warning' | 'danger' | 'info'`).
enum ConfirmTone { danger, warning, info }

/// Glassmorphism confirmation dialog — Dart port of `ConfirmationModal.tsx`
/// (Step 12 of FLUTTER_PLAN.md). Guards destructive operations such as season
/// reset (danger) and season change (warning).
///
/// Usage:
/// ```dart
/// final confirmed = await ConfirmationDialog.show(
///   context,
///   title: 'Reset Season',
///   message: 'This will erase all games in the current season.',
///   tone: ConfirmTone.danger,
///   details: 'This action cannot be undone.',
///   confirmLabel: 'Reset',
/// );
/// if (confirmed) _resetSeason();
/// ```
class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.tone = ConfirmTone.warning,
    this.details,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.onConfirm,
  });

  final String title;
  final String message;
  final ConfirmTone tone;

  /// Optional explanation rendered in a tone-tinted box (danger/warning) or a
  /// neutral box (info), mirroring `.modal-details` in
  /// `ConfirmationModal.css`.
  final String? details;
  final String confirmLabel;
  final String cancelLabel;

  /// Optional side effect run after the dialog resolves with `true`.
  final VoidCallback? onConfirm;

  /// Shows the dialog and resolves `true` when confirmed, `false` when
  /// cancelled (cancel button or tap outside, like the React overlay click).
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    ConfirmTone tone = ConfirmTone.warning,
    String? details,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    VoidCallback? onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => ConfirmationDialog(
        title: title,
        message: message,
        tone: tone,
        details: details,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
      ),
    );
    return confirmed ?? false;
  }

  Color _toneColor(ThemeData theme) => switch (tone) {
    ConfirmTone.danger => theme.colorScheme.error,
    ConfirmTone.warning => Colors.amber,
    ConfirmTone.info => theme.colorScheme.primary,
  };

  /// Mirrors the React emoji mapping: danger 🗑️, warning ⚠️, info ℹ️.
  IconData _toneIcon() => switch (tone) {
    ConfirmTone.danger => Icons.delete_outline_rounded,
    ConfirmTone.warning => Icons.warning_amber_rounded,
    ConfirmTone.info => Icons.info_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _toneColor(theme);
    final glass = theme.extension<GlassTheme>()!;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: tone icon + title.
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_toneIcon(), color: accent, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Body: message + optional details.
            Text(message, style: theme.textTheme.bodyMedium),
            if (details != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: tone == ConfirmTone.info
                      ? theme.colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        )
                      : accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: tone == ConfirmTone.info
                        ? glass.glassBorder
                        : accent.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(details!, style: theme.textTheme.bodySmall),
              ),
            ],
            const SizedBox(height: 20),

            // Actions: cancel (glass outline) + confirm (tone filled).
            // OverflowBar stacks the buttons on narrow screens, matching the
            // React <=480px column-reverse layout.
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 12,
              overflowSpacing: 8,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    side: BorderSide(color: glass.glassBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(cancelLabel),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    onConfirm?.call();
                  },
                  child: Text(confirmLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
