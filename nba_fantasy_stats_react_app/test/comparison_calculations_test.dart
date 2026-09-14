import 'package:flutter_test/flutter_test.dart';
import 'package:nba_fantasy_stats_react_app/models/season_awards.dart';
import 'package:nba_fantasy_stats_react_app/models/stats_summary.dart';
import 'package:nba_fantasy_stats_react_app/utils/comparison_calculations.dart';

const _awards = SeasonAwards(
  mvp: AwardWinner(player: 'Nikola Jokic', team: 'Denver Nuggets'),
  champion: Champion(team: 'Oklahoma City Thunder', record: '68-14'),
  scoringChampion: ScoringChampion(
    player: 'Shai Gilgeous-Alexander',
    team: 'Oklahoma City Thunder',
    ppg: 32.7,
  ),
  defensivePlayerOfYear: AwardWinner(
    player: 'Dyson Daniels',
    team: 'Atlanta Hawks',
  ),
  winningestTeam: WinningestTeam(
    team: 'Oklahoma City Thunder',
    record: '68-14',
    wins: 68,
  ),
);

StatsSummary _summary({
  int teamWins = 45,
  int teamLosses = 37,
  double points = 30.0,
  double assists = 6.0,
  double rebounds = 5.0,
  int currentStreak = 4,
}) => StatsSummary(
  wins: teamWins,
  losses: teamLosses,
  teamWins: teamWins,
  teamLosses: teamLosses,
  playerWins: teamWins,
  playerLosses: teamLosses,
  missedWins: 0,
  missedLosses: 0,
  gamesPlayed: teamWins + teamLosses,
  gamesMissed: 0,
  playoffWins: 0,
  playoffLosses: 0,
  playerWinPercentage: 0.55,
  missedWinPercentage: 0,
  currentStreak: currentStreak,
  longestWinStreak: 8,
  longestLossStreak: 2,
  winPercentage: 0.55,
  playoffWinPercentage: 0,
  buzzerBeaters: 0,
  regularBuzzerBeaters: 0,
  playoffBuzzerBeaters: 0,
  averages: StatAverages(
    points: points,
    assists: assists,
    rebounds: rebounds,
    blocks: 0,
    steals: 0,
    minutes: 0,
  ),
  seasonAverages: StatAverages(
    points: points,
    assists: assists,
    rebounds: rebounds,
    blocks: 0,
    steals: 0,
    minutes: 0,
  ),
  playoffAverages: const StatAverages(
    points: 0,
    assists: 0,
    rebounds: 0,
    blocks: 0,
    steals: 0,
    minutes: 0,
  ),
);

void main() {
  group('buildSeasonComparison', () {
    test('compares team record against the champion', () {
      final comparison = buildSeasonComparison(
        playerStats: _summary(teamWins: 45),
        seasonAwards: _awards,
      );

      expect(comparison.teamRecord, '45-37');
      expect(comparison.teamRecordEntry.playerValue, 45);
      expect(comparison.teamRecordEntry.referenceValue, 68);
      expect(comparison.teamRecordEntry.difference, -23);
      expect(comparison.teamRecordEntry.isBetter, isFalse);
      expect(comparison.championTeam, 'Oklahoma City Thunder');
      expect(comparison.championRecord, '68-14');
    });

    test('currentRecord overrides the summary record', () {
      final comparison = buildSeasonComparison(
        playerStats: _summary(teamWins: 45),
        seasonAwards: _awards,
        currentRecord: '70-12',
      );

      expect(comparison.teamRecord, '70-12');
      expect(comparison.teamRecordEntry.playerValue, 70);
      expect(comparison.teamRecordEntry.isBetter, isTrue);
    });

    test('compares PPG against the scoring champion', () {
      final comparison = buildSeasonComparison(
        playerStats: _summary(points: 30.0),
        seasonAwards: _awards,
      );

      final ppg = comparison.statEntries.first;
      expect(
        ppg.label,
        'PPG vs Shai Gilgeous-Alexander (Oklahoma City Thunder)',
      );
      expect(ppg.playerValue, 30.0);
      expect(ppg.referenceValue, 32.7);
      expect(ppg.difference, closeTo(-2.7, 0.001));
      expect(ppg.isBetter, isFalse);
    });

    test('compares APG and RPG against league averages', () {
      final comparison = buildSeasonComparison(
        playerStats: _summary(assists: 10.0, rebounds: 4.0),
        seasonAwards: _awards,
      );

      final apg = comparison.statEntries[1];
      expect(apg.label, 'APG vs League Average');
      expect(apg.referenceValue, 8.0);
      expect(apg.isBetter, isTrue);

      final rpg = comparison.statEntries[2];
      expect(rpg.label, 'RPG vs League Average');
      expect(rpg.referenceValue, 7.0);
      expect(rpg.isBetter, isFalse);
    });

    test('handles a null playerStats as zeroed averages', () {
      final comparison = buildSeasonComparison(
        playerStats: null,
        seasonAwards: _awards,
      );

      expect(comparison.teamRecord, '0-0');
      expect(comparison.teamRecordEntry.playerValue, 0);
      expect(comparison.statEntries.every((e) => e.playerValue == 0), isTrue);
    });

    test('throws when seasonAwards is missing', () {
      expect(
        () => buildSeasonComparison(playerStats: null, seasonAwards: null),
        throwsArgumentError,
      );
    });

    test('computes the record percentage against champion wins', () {
      final comparison = buildSeasonComparison(
        playerStats: _summary(teamWins: 34),
        seasonAwards: _awards,
      );

      // 34 vs 68 wins = -50%.
      expect(comparison.teamRecordEntry.percentage, closeTo(-50.0, 0.001));
    });
  });

  group('formatting helpers', () {
    test('formatDifference signs both number and percentage', () {
      const positive = ComparisonEntry(
        label: 'l',
        playerValue: 33,
        referenceValue: 30,
        difference: 3,
        percentage: 10,
        isBetter: true,
      );
      expect(formatDifference(positive), '+3.0 (+10.0%)');

      const negative = ComparisonEntry(
        label: 'l',
        playerValue: 28,
        referenceValue: 30,
        difference: -2.5,
        percentage: -8.3,
        isBetter: false,
      );
      expect(formatDifference(negative), '-2.5 (-8.3%)');
    });

    test('formatValuePair renders player vs reference', () {
      const entry = ComparisonEntry(
        label: 'l',
        playerValue: 30.25,
        referenceValue: 32.7,
        difference: -2.45,
        percentage: -7.5,
        isBetter: false,
      );
      // Dart rounds half away from zero: 30.25 -> 30.3.
      expect(formatValuePair(entry), '30.3 vs 32.7');
    });

    test('formatStreak renders W/L/None', () {
      expect(formatStreak(4), 'W4');
      expect(formatStreak(-2), 'L2');
      expect(formatStreak(0), 'None');
    });

    test('formatWinPercentage renders one decimal percent', () {
      expect(formatWinPercentage(0.8125), '81.3%');
      expect(formatWinPercentage(0), '0.0%');
    });
  });
}
