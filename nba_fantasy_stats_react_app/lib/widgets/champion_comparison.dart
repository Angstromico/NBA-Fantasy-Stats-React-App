import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats_react_app/models/season_awards.dart';
import 'package:nba_fantasy_stats_react_app/models/stats_summary.dart';
import 'package:nba_fantasy_stats_react_app/theme/app_theme.dart';
import 'package:nba_fantasy_stats_react_app/utils/comparison_calculations.dart';
import 'package:nba_fantasy_stats_react_app/widgets/glass_card.dart';

/// Champion comparison — Dart port of `ComparisonDisplay.tsx` (Step 11 of
/// FLUTTER_PLAN.md). Compares the **current season only** team record and
/// player averages against that season's champion and award winners.
///
/// Season integrity: callers must pass only the current season's games via
/// [playerStats]; never career totals.
class ChampionComparison extends StatelessWidget {
  const ChampionComparison({
    super.key,
    required this.playerStats,
    required this.seasonAwards,
    required this.playerTeam,
    required this.season,
    this.currentRecord,
  });

  /// Current-season aggregate (from `calculateStatsSummary`) or null when no
  /// games are logged yet this season.
  final StatsSummary? playerStats;

  /// Historical awards for the selected season; null renders nothing,
  /// mirroring the React component's early return.
  final SeasonAwards? seasonAwards;

  final String playerTeam;
  final String season;

  /// Optional record override, e.g. `45-37` (App.tsx passes
  /// `${teamWins}-${teamLosses}` of the current season).
  final String? currentRecord;

  @override
  Widget build(BuildContext context) {
    final awards = seasonAwards;
    if (awards == null) {
      return const SizedBox.shrink();
    }

    final comparison = buildSeasonComparison(
      playerStats: playerStats,
      seasonAwards: seasonAwards,
      currentRecord: currentRecord,
    );
    final theme = Theme.of(context);
    final success = _successColor(theme);
    final error = theme.colorScheme.error;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'NBA Comparison - $season Season',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Team performance vs champions.
          _sectionTitle(theme, 'Team Performance vs Champions'),
          _comparisonRow(
            theme: theme,
            entry: comparison.teamRecordEntry,
            playerDisplay: comparison.teamRecord,
            referenceDisplay:
                '${comparison.championRecord} (${comparison.championTeam})',
            differenceDisplay:
                '${comparison.teamRecordEntry.difference >= 0 ? '+' : ''}'
                '${comparison.teamRecordEntry.difference.toInt()} wins '
                '(${comparison.teamRecordEntry.difference >= 0 ? '+' : ''}'
                '${comparison.teamRecordEntry.percentage.toStringAsFixed(1)}%)',
            accent: comparison.teamRecordEntry.isBetter ? success : error,
          ),
          const SizedBox(height: 12),
          _infoBox(theme, [
            '🏆 Champion: ${comparison.championTeam}',
            '🏆 Record: ${comparison.championRecord}',
          ]),
          const SizedBox(height: 16),

          // Individual performance vs award winners.
          _sectionTitle(theme, 'Individual Performance vs Award Winners'),
          for (final entry in comparison.statEntries)
            _comparisonRow(
              theme: theme,
              entry: entry,
              playerDisplay: entry.playerValue.toStringAsFixed(1),
              referenceDisplay: entry.referenceValue.toStringAsFixed(1),
              differenceDisplay: formatDifference(entry),
              accent: entry.isBetter ? success : error,
            ),
          const SizedBox(height: 12),
          _infoBox(theme, [
            '⭐ MVP: ${awards.mvp.player} (${awards.mvp.team})',
            '⭐ Scoring Champion: '
                '${awards.scoringChampion.player} '
                '(${awards.scoringChampion.team}) - '
                '${awards.scoringChampion.ppg} PPG',
            '⭐ Defensive Player: '
                '${awards.defensivePlayerOfYear.player} '
                '(${awards.defensivePlayerOfYear.team})',
            '⭐ Winningest Team: ${awards.winningestTeam.team} '
                '(${awards.winningestTeam.record})',
          ]),
          const SizedBox(height: 16),

          // Season summary grid.
          _sectionTitle(theme, 'Season Summary'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _summaryTile(theme, 'Your Team', playerTeam),
              _summaryTile(
                theme,
                'Games Played',
                '${playerStats?.gamesPlayed ?? 0}',
              ),
              _summaryTile(
                theme,
                'Games Missed',
                '${playerStats?.gamesMissed ?? 0}',
              ),
              _summaryTile(
                theme,
                'Player Record',
                '${playerStats?.playerWins ?? 0}-'
                    '${playerStats?.playerLosses ?? 0}',
              ),
              _summaryTile(
                theme,
                'Team Total',
                '${playerStats?.teamWins ?? 0}-'
                    '${playerStats?.teamLosses ?? 0}',
              ),
              _summaryTile(
                theme,
                'Player Win %',
                formatWinPercentage(playerStats?.playerWinPercentage ?? 0),
              ),
              _summaryTile(
                theme,
                'Current Streak',
                formatStreak(playerStats?.currentStreak ?? 0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// `--accent-success` for the current brightness (not in `ColorScheme`).
  Color _successColor(ThemeData theme) => theme.brightness == Brightness.dark
      ? AppTheme.successDark
      : AppTheme.successLight;

  Widget _sectionTitle(ThemeData theme, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title.toUpperCase(),
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.secondary,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _comparisonRow({
    required ThemeData theme,
    required ComparisonEntry entry,
    required String playerDisplay,
    required String referenceDisplay,
    required String differenceDisplay,
    required Color accent,
  }) => Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border(left: BorderSide(color: accent, width: 4)),
    ),
    child: Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '${entry.label}:',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          playerDisplay,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          'vs',
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
        Text(referenceDisplay, style: theme.textTheme.bodyMedium),
        Text(
          differenceDisplay,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ],
    ),
  );

  Widget _infoBox(ThemeData theme, List<String> lines) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: theme.colorScheme.outlineVariant),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(line, style: theme.textTheme.bodySmall),
          ),
      ],
    ),
  );

  Widget _summaryTile(ThemeData theme, String label, String value) {
    final glass = theme.extension<GlassTheme>()!;
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: glass.glassColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: glass.glassBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
