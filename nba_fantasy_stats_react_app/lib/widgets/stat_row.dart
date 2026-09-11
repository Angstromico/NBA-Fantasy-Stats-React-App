import 'package:flutter/material.dart';

/// Label / value row used across the summary and records screens
/// (mirrors the table cells of the React summary page).
class StatRow extends StatelessWidget {
  const StatRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;

  /// Renders the value bold with the primary color — used to highlight
  /// headline rows like the player record.
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: emphasize
                ? theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  )
                : theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
