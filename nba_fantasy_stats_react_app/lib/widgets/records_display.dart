import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats_react_app/models/game_stats.dart';
import 'package:nba_fantasy_stats_react_app/utils/record_calculations.dart';
import 'package:nba_fantasy_stats_react_app/widgets/glass_card.dart';

/// Record chase — Dart port of `RecordsDisplay.tsx`. Shows the player's
/// career-best streaks and compares them against real, verifiable NBA
/// records, with a dismissible congratulations banner for newly broken
/// records.
class RecordsDisplay extends StatelessWidget {
  const RecordsDisplay({
    super.key,
    required this.stats,
    this.congrats = const [],
    this.onDismissCongrats,
  });

  final List<GameStats> stats;
  final List<RecordComparison> congrats;
  final VoidCallback? onDismissCongrats;

  static String _formatDate(String? date) {
    if (date == null || date.isEmpty) return '';
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
  }

  static String _formatStreakLabel(int value, String letter) =>
      value > 0 ? '$letter$value' : 'None';

  static String _congratsMessage(RecordComparison comparison) {
    final record = comparison.record;
    final action = comparison.playerValue > record.value
        ? 'broke'
        : 'matched (tied)';
    return "Your player $action the NBA record for ${record.label} — "
        "${record.holder}'s ${record.value} ${record.unit} "
        '(${record.season}) — with ${comparison.playerValue} '
        '${record.unit}!';
  }

  @override
  Widget build(BuildContext context) {
    final achievements = getRecordAchievements(stats);
    final comparisons = compareToNBARecords(achievements);
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    final streakCards = [
      (
        title: 'Win Streak',
        current: _formatStreakLabel(achievements.currentWinStreak, 'W'),
        best: _formatStreakLabel(achievements.longestWinStreak, 'W'),
        range: achievements.longestWinStart == null
            ? ''
            : '${_formatDate(achievements.longestWinStart)} — '
                  '${_formatDate(achievements.longestWinEnd)}',
      ),
      (
        title: 'Loss Streak',
        current: _formatStreakLabel(achievements.currentLossStreak, 'L'),
        best: _formatStreakLabel(achievements.longestLossStreak, 'L'),
        range: achievements.longestLossStart == null
            ? ''
            : '${_formatDate(achievements.longestLossStart)} — '
                  '${_formatDate(achievements.longestLossEnd)}',
      ),
      ...achievements.scoringStreaks.map(
        (streak) => (
          title: '${streak.threshold}+ Point Games',
          current: _formatStreakLabel(streak.current, ''),
          best: _formatStreakLabel(streak.longest, ''),
          range: streak.longestStart == null
              ? ''
              : '${_formatDate(streak.longestStart)} — '
                    '${_formatDate(streak.longestEnd)}',
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero.
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Record chase', style: theme.textTheme.labelSmall),
              Text('NBA Records', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                "Follow your player's career-best streaks and see how they "
                'stack up against the greatest records in NBA history.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Congrats banner.
        if (congrats.isNotEmpty)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final comparison in congrats)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '🏆 ${_congratsMessage(comparison)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (onDismissCongrats != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Dismiss congratulations',
                      onPressed: onDismissCongrats,
                      icon: const Icon(Icons.close),
                    ),
                  ),
              ],
            ),
          ),
        if (congrats.isNotEmpty) const SizedBox(height: 12),

        if (stats.isEmpty)
          GlassCard(
            child: Column(
              children: [
                Text('No games logged yet', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Submit games from the tracker to start building streaks '
                  'and chasing NBA records.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          )
        else ...[
          // Career top streaks.
          _sectionTitle(theme, 'Career Top Streaks'),
          GlassCard(
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                for (final card in streakCards)
                  SizedBox(
                    width: 150,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(card.title, style: theme.textTheme.labelMedium),
                        const SizedBox(height: 4),
                        _streakValue(theme, 'Current', card.current),
                        _streakValue(theme, 'Best', card.best, isBest: true),
                        if (card.range.isNotEmpty)
                          Text(card.range, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Real NBA records table.
          _sectionTitle(theme, 'Real NBA Records'),
          GlassCard(
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(1.4),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                  children: [
                    _headCell(theme, 'Record'),
                    _headCell(theme, 'Your Best'),
                    _headCell(theme, 'NBA Record'),
                    _headCell(theme, 'Status'),
                  ],
                ),
                for (final comparison in comparisons)
                  TableRow(
                    decoration: BoxDecoration(
                      color: comparison.broken
                          ? accent.withValues(alpha: 0.10)
                          : null,
                      border: Border(
                        bottom: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    children: [
                      // Record + detail.
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comparison.record.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              comparison.record.detail,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      // Your best.
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${comparison.playerValue}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (comparison.currentValue != null &&
                                comparison.currentValue! > 0)
                              Text(
                                'Current: ${comparison.currentValue} '
                                '${comparison.record.unit}',
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      // NBA record.
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comparison.record.holder +
                                  (comparison.record.team == null
                                      ? ''
                                      : ' (${comparison.record.team})'),
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              '${comparison.record.value} '
                              '${comparison.record.unit} · '
                              '${comparison.record.season}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      // Status.
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: comparison.broken
                            ? Text(
                                '🏆 BROKEN',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : Text(
                                '${comparison.remaining} '
                                '${comparison.record.unit} to go',
                                style: theme.textTheme.bodySmall,
                              ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 8),
    child: Text(title, style: theme.textTheme.titleLarge),
  );

  Widget _streakValue(
    ThemeData theme,
    String label,
    String value, {
    bool isBest = false,
  }) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: theme.textTheme.bodySmall),
      Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: isBest ? theme.colorScheme.primary : null,
        ),
      ),
    ],
  );

  Widget _headCell(ThemeData theme, String text, {bool alignRight = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          text,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}
