import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nba_fantasy_stats_react_app/models/enums.dart';
import 'package:nba_fantasy_stats_react_app/models/game_stats.dart';
import 'package:nba_fantasy_stats_react_app/theme/app_theme.dart';
import 'package:nba_fantasy_stats_react_app/utils/stats_calculations.dart';
import 'package:nba_fantasy_stats_react_app/widgets/tracker_stats_section.dart';

GameStats _game({
  int points = 20,
  int assists = 5,
  int rebounds = 6,
  int blocks = 1,
  int steals = 1,
  int minutes = 34,
  bool won = true,
  bool isAbsent = false,
  bool buzzer = false,
  GameType gameType = GameType.regular,
  int gameNumber = 1,
  String season = '2024-2025',
  String date = '2024-10-22',
}) => GameStats(
  id: 'g$gameNumber-$season-$points-$assists',
  date: date,
  team: 'Boston Celtics',
  opponent: 'New York Knicks',
  gameNumber: gameNumber,
  gameType: gameType,
  absenceType: isAbsent ? AbsenceType.rest : AbsenceType.none,
  isAbsent: isAbsent,
  points: points,
  assists: assists,
  rebounds: rebounds,
  blocks: blocks,
  steals: steals,
  minutes: minutes,
  won: won,
  isDoubleDouble: false,
  isTripleDouble: false,
  isBuzzerBeater: buzzer,
  season: season,
);

Future<void> _pumpSection(WidgetTester tester, List<GameStats> games) async {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: TrackerStatsSection(
            stats: games,
            careerHighs: calculateCareerHighs(games),
            statsSummary: calculateStatsSummary(games),
            seasonStats: organizeSeasonStats(games),
            currentSeason: '2024-2025',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders section headings and the last five games by default', (
    tester,
  ) async {
    final games = List.generate(7, (i) => _game(gameNumber: i + 1));
    await _pumpSection(tester, games);

    expect(find.text('Game Statistics'), findsOneWidget);
    expect(find.text('Overall Summary'), findsOneWidget);
    expect(find.text('Season by Season Stats'), findsOneWidget);
    // Section heading + the flip card's own face title.
    expect(find.text('Statistical Milestones'), findsNWidgets(2));
    expect(find.text('Career Highs'), findsOneWidget);
    expect(find.text('Career Totals'), findsOneWidget);

    // Only the last 5 of 7 games are shown initially (games 3-7).
    expect(find.textContaining('Game 7'), findsOneWidget);
    expect(find.textContaining('Game 2'), findsNothing);

    // Toggle reveals every game.
    await tester.tap(find.text('Show All Games'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Game 2'), findsOneWidget);
  });

  testWidgets('record card shows season face and flips to career totals', (
    tester,
  ) async {
    final games = [
      _game(gameNumber: 1, won: true),
      _game(gameNumber: 2, won: false),
      _game(
        gameNumber: 3,
        won: true,
        gameType: GameType.playoffs,
        season: '2023-2024',
        date: '2024-04-20',
      ),
    ];
    await _pumpSection(tester, games);

    // Record card face + the averages block heading.
    expect(find.text('Current Season'), findsNWidgets(2));
    expect(find.text('2024-2025'), findsOneWidget);
    expect(find.text('Team Total: 1-1'), findsOneWidget);
    expect(find.text('Player Games: 1-1'), findsOneWidget);
    expect(find.text('Tap for career totals'), findsOneWidget);

    await tester.tap(find.text('Tap for career totals'));
    await tester.pumpAndSettle();

    expect(find.text('Career Totals'), findsNWidgets(2));
    expect(find.text('Team Total: 2-1'), findsOneWidget);
    expect(find.text('Playoffs Team Total: 1-0'), findsOneWidget);
    expect(find.text('Tap for current season'), findsOneWidget);
  });

  testWidgets('shows streaks, win percentages and season averages', (
    tester,
  ) async {
    final games = [
      for (var i = 1; i <= 4; i++) _game(gameNumber: i, won: i.isEven),
    ];
    await _pumpSection(tester, games);

    expect(find.text('Current Streak: W1'), findsOneWidget);
    expect(find.text('Longest Win Streak: 1'), findsOneWidget);
    expect(find.text('Longest Loss Streak: 1'), findsOneWidget);
    expect(find.text('Team Win Percentage: 50.00%'), findsOneWidget);

    // Averages block exists with all six categories.
    for (final label in [
      'Points',
      'Assists',
      'Rebounds',
      'Steals',
      'Minutes',
    ]) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text('Current Season'), findsWidgets);
    expect(find.text('Overall'), findsOneWidget);
    expect(find.text('Regular Season'), findsOneWidget);
  });

  testWidgets('season-by-season cards and career totals panel are populated', (
    tester,
  ) async {
    final games = [
      _game(gameNumber: 1),
      _game(gameNumber: 2, season: '2023-2024', date: '2023-10-25'),
    ];
    await _pumpSection(tester, games);

    expect(find.text('2024-2025 Season'), findsOneWidget);
    expect(find.text('2023-2024 Season'), findsOneWidget);
    // One record line per season card (each season is 1-0).
    expect(find.text('Team Total Record: 1-0'), findsNWidgets(2));

    expect(find.text('Total Points'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
    expect(find.text('Total Games: 2'), findsNothing);
    expect(find.text('Total Games'), findsOneWidget);
    // blocks, steals, total games and games played all equal 2.
    expect(find.text('2'), findsNWidgets(4));
    expect(find.text('Games Absent'), findsOneWidget);
    // The zero value is rendered in several numeric panels (milestones among
    // them) — assert presence rather than an exact count.
    expect(find.text('0'), findsWidgets);
  });

  testWidgets('absent games render with the absence type and are excluded '
      'from player averages', (tester) async {
    final games = [
      _game(gameNumber: 1, isAbsent: true, won: false),
      _game(gameNumber: 2, won: false, points: 10),
    ];
    await _pumpSection(tester, games);

    expect(find.textContaining('Absent:'), findsOneWidget);
    // Player Games excludes the absence from the W column: 0-1.
    expect(find.text('Player Games: 0-1'), findsOneWidget);
    expect(find.text('Missed Games Record: 0-1'), findsOneWidget);
  });

  testWidgets('career highs panel lists every tracked high', (tester) async {
    final games = [_game(gameNumber: 1, points: 44, buzzer: true)];
    await _pumpSection(tester, games);

    expect(find.text('Points'), findsWidgets);
    expect(find.text('44'), findsWidgets);
    expect(find.text('Career Double-Doubles'), findsOneWidget);
    expect(find.text('Career Triple-Doubles'), findsOneWidget);
    expect(find.text('Total Buzzer Beaters'), findsOneWidget);
    expect(find.text('1 🔥'), findsOneWidget);
  });
}
