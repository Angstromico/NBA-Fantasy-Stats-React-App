import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nba_fantasy_stats_react_app/models/season_awards.dart';
import 'package:nba_fantasy_stats_react_app/models/stats_summary.dart';
import 'package:nba_fantasy_stats_react_app/theme/app_theme.dart';
import 'package:nba_fantasy_stats_react_app/widgets/champion_comparison.dart';

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

StatsSummary _summary({int teamWins = 45, int teamLosses = 37}) => StatsSummary(
  wins: teamWins,
  losses: teamLosses,
  teamWins: teamWins,
  teamLosses: teamLosses,
  playerWins: teamWins,
  playerLosses: teamLosses,
  missedWins: 0,
  missedLosses: 0,
  gamesPlayed: teamWins + teamLosses,
  gamesMissed: 2,
  playoffWins: 0,
  playoffLosses: 0,
  playerWinPercentage: 0.55,
  missedWinPercentage: 0,
  currentStreak: 4,
  longestWinStreak: 8,
  longestLossStreak: 2,
  winPercentage: 0.55,
  playoffWinPercentage: 0,
  buzzerBeaters: 0,
  regularBuzzerBeaters: 0,
  playoffBuzzerBeaters: 0,
  averages: const StatAverages(
    points: 30.0,
    assists: 6.0,
    rebounds: 5.0,
    blocks: 0,
    steals: 0,
    minutes: 0,
  ),
  seasonAverages: const StatAverages(
    points: 30.0,
    assists: 6.0,
    rebounds: 5.0,
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

Future<void> _pumpComparison(
  WidgetTester tester, {
  StatsSummary? playerStats,
  SeasonAwards? seasonAwards = _awards,
  String? currentRecord,
}) async {
  tester.view.physicalSize = const Size(900, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ChampionComparison(
            playerStats: playerStats,
            seasonAwards: seasonAwards,
            playerTeam: 'MyTeam',
            season: '2025-26',
            currentRecord: currentRecord,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ChampionComparison', () {
    testWidgets('renders nothing without season awards', (tester) async {
      await _pumpComparison(tester, seasonAwards: null);
      expect(find.byType(ChampionComparison), findsOneWidget);
      expect(find.text('NBA Comparison - 2025-26 Season'), findsNothing);
    });

    testWidgets('renders all three sections', (tester) async {
      await _pumpComparison(tester, playerStats: _summary());

      expect(find.text('NBA Comparison - 2025-26 Season'), findsOneWidget);
      expect(find.text('TEAM PERFORMANCE VS CHAMPIONS'), findsOneWidget);
      expect(
        find.text('INDIVIDUAL PERFORMANCE VS AWARD WINNERS'),
        findsOneWidget,
      );
      expect(find.text('SEASON SUMMARY'), findsOneWidget);
    });

    testWidgets('compares the team record against the champion', (
      tester,
    ) async {
      await _pumpComparison(tester, playerStats: _summary());

      // Record row, Player Record tile, and Team Total tile.
      expect(find.text('45-37'), findsNWidgets(3));
      expect(find.textContaining('Oklahoma City Thunder'), findsWidgets);
      expect(find.textContaining('-23 wins'), findsOneWidget);
    });

    testWidgets('uses currentRecord when provided', (tester) async {
      await _pumpComparison(
        tester,
        playerStats: _summary(),
        currentRecord: '70-12',
      );

      expect(find.text('70-12'), findsOneWidget);
      expect(find.textContaining('+2 wins'), findsOneWidget);
    });

    testWidgets('compares averages against award winners', (tester) async {
      await _pumpComparison(tester, playerStats: _summary());

      expect(
        find.text('PPG vs Shai Gilgeous-Alexander (Oklahoma City Thunder):'),
        findsOneWidget,
      );
      expect(find.text('APG vs League Average:'), findsOneWidget);
      expect(find.text('RPG vs League Average:'), findsOneWidget);
      expect(find.text('30.0'), findsOneWidget);
      expect(find.text('32.7'), findsOneWidget);
    });

    testWidgets('lists award winners and champion info', (tester) async {
      await _pumpComparison(tester, playerStats: _summary());

      expect(find.textContaining('🏆 Champion:'), findsOneWidget);
      expect(find.textContaining('🏆 Record:'), findsOneWidget);
      expect(find.textContaining('⭐ MVP:'), findsOneWidget);
      expect(find.textContaining('⭐ Scoring Champion:'), findsOneWidget);
      expect(find.textContaining('⭐ Defensive Player:'), findsOneWidget);
      expect(find.textContaining('⭐ Winningest Team:'), findsOneWidget);
    });

    testWidgets('shows season summary tiles', (tester) async {
      await _pumpComparison(tester, playerStats: _summary());

      expect(find.text('Your Team'), findsOneWidget);
      expect(find.text('MyTeam'), findsOneWidget);
      expect(find.text('Games Played'), findsOneWidget);
      expect(find.text('82'), findsOneWidget);
      expect(find.text('Games Missed'), findsOneWidget);
      expect(find.text('Player Record'), findsOneWidget);
      // Record row + Player Record tile + Team Total tile.
      expect(find.text('45-37'), findsNWidgets(3));
      expect(find.text('W4'), findsOneWidget);
    });

    testWidgets('handles a null playerStats with zeroed values', (
      tester,
    ) async {
      await _pumpComparison(tester, playerStats: null);

      // Record row + Player Record tile + Team Total tile.
      expect(find.text('0-0'), findsNWidgets(3));
      expect(find.text('None'), findsOneWidget); // current streak
    });
  });
}
