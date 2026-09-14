import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats_react_app/utils/leaderboard_calculations.dart';
import 'package:nba_fantasy_stats_react_app/utils/record_calculations.dart';

/// The `congrats-banner` blocks in App.tsx — gold-tinted celebratory
/// messages for newly broken NBA records and top-20 leaderboard entrances,
/// with a dismiss button (`congrats-dismiss`).
class GlassBannerCard extends StatelessWidget {
  const GlassBannerCard({
    super.key,
    required this.records,
    required this.entrances,
    required this.onDismiss,
    required this.textStyle,
  });

  final List<RecordComparison> records;
  final List<TopTwentyEntrance> entrances;
  final VoidCallback onDismiss;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const gold = Color(0xFFFACC15);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: gold.withValues(alpha: 0.12),
        border: Border.all(color: gold.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final comparison in records)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '🏆 CONGRATULATIONS! You broke the NBA record for '
                      '${comparison.record.label} (${comparison.record.holder}, '
                      '${comparison.record.value} ${comparison.record.unit}) '
                      'with ${comparison.playerValue} '
                      '${comparison.record.unit}!',
                      style: textStyle,
                    ),
                  ),
                for (final entrance in entrances)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '🏆 TOP-20 ENTRY! Your ${entrance.value}-'
                      '${entrance.adjective} game (${entrance.context}) '
                      'ranks #${entrance.rank} all-time for '
                      '${entrance.boardTitle}!',
                      style: textStyle,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Dismiss congratulations',
            visualDensity: VisualDensity.compact,
            onPressed: onDismiss,
            icon: Icon(
              Icons.close,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
