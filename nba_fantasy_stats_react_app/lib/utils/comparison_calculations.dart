import 'package:nba_fantasy_stats_react_app/models/season_awards.dart';
import 'package:nba_fantasy_stats_react_app/models/stats_summary.dart';

/// Pure Dart helpers for `ChampionComparison` (Step 11 of FLUTTER_PLAN.md) —
/// mirrors the inline formatting in `ComparisonDisplay.tsx` without any
/// Flutter dependencies.

/// One `player vs reference` comparison row.
class ComparisonEntry {
  const ComparisonEntry({
    required this.label,
    required this.playerValue,
    required this.referenceValue,
    required this.difference,
    required this.percentage,
    required this.isBetter,
  });

  /// Row label, e.g. `PPG vs Shai Gilgeous-Alexander (OKC)`.
  final String label;

  /// The player's value (average or record parse).
  final double playerValue;

  /// The reference value (award winner, league average, champion wins).
  final double referenceValue;

  /// `playerValue - referenceValue`.
  final double difference;

  /// Relative difference vs the reference, in percent
  /// (`0` when the reference is zero).
  final double percentage;

  /// Whether the player leads the reference.
  final bool isBetter;
}

/// Aggregated comparison rows for the current season, mirroring the blocks of
/// `ComparisonDisplay.tsx`.
class SeasonComparison {
  const SeasonComparison({
    required this.teamRecord,
    required this.teamRecordEntry,
    required this.statEntries,
    required this.championTeam,
    required this.championRecord,
  });

  /// Player team record, e.g. `45-37` — `currentRecord` when provided,
  /// else `teamWins-teamLosses` from the summary.
  final String teamRecord;

  /// Wins comparison against the champion's record.
  final ComparisonEntry teamRecordEntry;

  /// PPG vs scoring champion, APG/RPG vs league averages.
  final List<ComparisonEntry> statEntries;

  /// Champion team name and record for the info block.
  final String championTeam;
  final String championRecord;
}

/// Approximate league averages hardcoded in ComparisonDisplay.tsx.
const double _leagueAverageApg = 8.0;
const double _leagueAverageRpg = 7.0;

String _fmt1(double value) => value.toStringAsFixed(1);

double _parseWins(String record) {
  final wins = record.split('-').first;
  return double.tryParse(wins) ?? 0;
}

/// Builds every `vs champions / award winners` comparison for the current
/// season. Mirrors `compareTeamRecords` + `formatComparison` in
/// ComparisonDisplay.tsx.
SeasonComparison buildSeasonComparison({
  required StatsSummary? playerStats,
  required SeasonAwards? seasonAwards,
  String? currentRecord,
}) {
  if (seasonAwards == null) {
    throw ArgumentError('seasonAwards is required to build a comparison');
  }

  final champion = seasonAwards.champion;
  final championWins = _parseWins(champion.record);

  final teamRecord =
      currentRecord ??
      '${playerStats?.teamWins ?? 0}-${playerStats?.teamLosses ?? 0}';
  final playerWins = _parseWins(teamRecord);
  final recordDifference = playerWins - championWins;
  final recordPercentage = championWins > 0
      ? recordDifference / championWins * 100
      : 0.0;

  final teamRecordEntry = ComparisonEntry(
    label: 'Current Record',
    playerValue: playerWins,
    referenceValue: championWins,
    difference: recordDifference,
    percentage: recordPercentage,
    isBetter: recordDifference >= 0,
  );

  final averages = playerStats?.averages;

  return SeasonComparison(
    teamRecord: teamRecord,
    teamRecordEntry: teamRecordEntry,
    statEntries: [
      ComparisonEntry(
        label:
            'PPG vs ${seasonAwards.scoringChampion.player} '
            '(${seasonAwards.scoringChampion.team})',
        playerValue: averages?.points ?? 0,
        referenceValue: seasonAwards.scoringChampion.ppg,
        difference: (averages?.points ?? 0) - seasonAwards.scoringChampion.ppg,
        percentage: seasonAwards.scoringChampion.ppg > 0
            ? (((averages?.points ?? 0) - seasonAwards.scoringChampion.ppg) /
                  seasonAwards.scoringChampion.ppg *
                  100)
            : 0,
        isBetter: (averages?.points ?? 0) > seasonAwards.scoringChampion.ppg,
      ),
      ComparisonEntry(
        label: 'APG vs League Average',
        playerValue: averages?.assists ?? 0,
        referenceValue: _leagueAverageApg,
        difference: (averages?.assists ?? 0) - _leagueAverageApg,
        percentage: _leagueAverageApg > 0
            ? ((averages?.assists ?? 0) - _leagueAverageApg) /
                  _leagueAverageApg *
                  100
            : 0,
        isBetter: (averages?.assists ?? 0) > _leagueAverageApg,
      ),
      ComparisonEntry(
        label: 'RPG vs League Average',
        playerValue: averages?.rebounds ?? 0,
        referenceValue: _leagueAverageRpg,
        difference: (averages?.rebounds ?? 0) - _leagueAverageRpg,
        percentage: _leagueAverageRpg > 0
            ? ((averages?.rebounds ?? 0) - _leagueAverageRpg) /
                  _leagueAverageRpg *
                  100
            : 0,
        isBetter: (averages?.rebounds ?? 0) > _leagueAverageRpg,
      ),
    ],
    championTeam: champion.team,
    championRecord: champion.record,
  );
}

/// Formats the signed difference string, e.g. `+3.0 (+5.1%)` / `-2.4 (-8.0%)`.
String formatDifference(ComparisonEntry entry) =>
    '${entry.difference >= 0 ? '+' : ''}${_fmt1(entry.difference)} '
    '(${entry.difference >= 0 ? '+' : ''}${_fmt1(entry.percentage)}%)';

/// Formats a comparison row value pair, e.g. `30.2 vs 32.7`.
String formatValuePair(ComparisonEntry entry) =>
    '${_fmt1(entry.playerValue)} vs ${_fmt1(entry.referenceValue)}';

/// Formats the current streak, e.g. `W4` / `L2` / `None`.
String formatStreak(int streak) => streak > 0
    ? 'W$streak'
    : streak < 0
    ? 'L${streak.abs()}'
    : 'None';

/// Formats a win percentage as `81.3%`.
String formatWinPercentage(double value) =>
    '${(value * 100).toStringAsFixed(1)}%';
