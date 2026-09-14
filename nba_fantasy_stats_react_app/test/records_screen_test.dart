import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nba_fantasy_stats_react_app/models/enums.dart';
import 'package:nba_fantasy_stats_react_app/models/game_stats.dart';
import 'package:nba_fantasy_stats_react_app/screens/records_screen.dart';
import 'package:nba_fantasy_stats_react_app/theme/app_theme.dart';
import 'package:nba_fantasy_stats_react_app/utils/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

GameStats _game({
  int points = 0,
  bool won = false,
  bool isAbsent = false,
  bool isTripleDouble = false,
  GameType gameType = GameType.regular,
  String season = '2025-26',
  String date = '2026-01-15',
  int gameNumber = 1,
}) => GameStats(
  id: '${date}_${gameNumber}_$points$won$season',
  date: date,
  team: 'MyTeam',
  opponent: 'Rivals',
  gameNumber: gameNumber,
  gameType: gameType,
  absenceType: isAbsent ? AbsenceType.rest : AbsenceType.none,
  isAbsent: isAbsent,
  points: points,
  assists: 0,
  rebounds: 0,
  blocks: 0,
  steals: 0,
  minutes: 0,
  won: won,
  isDoubleDouble: false,
  isTripleDouble: isTripleDouble,
  isBuzzerBeater: false,
  season: season,
);

Future<void> _pumpRecords(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: const RecordsScreen(username: 'manuel'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    StorageService.setInstance(await SharedPreferences.getInstance());
  });

  group('RecordsScreen empty state', () {
    testWidgets('shows both empty states with no games', (tester) async {
      await _pumpRecords(tester);

      expect(find.text('NBA Records'), findsOneWidget);
      expect(find.text('Top 20 Leaderboards'), findsOneWidget);
      expect(find.text('No games logged yet'), findsNWidgets(2));
    });
  });

  group('RecordsScreen with games', () {
    testWidgets('renders streak cards and NBA records table', (tester) async {
      await StorageService.writeJson(StorageService.gamesKey, [
        _game(points: 30, won: true, date: '2026-01-01'),
        _game(points: 12, won: true, date: '2026-01-02'),
      ]);
      await _pumpRecords(tester);

      // Streak cards.
      expect(find.text('Career Top Streaks'), findsOneWidget);
      expect(find.text('Win Streak'), findsOneWidget);
      expect(find.text('Loss Streak'), findsOneWidget);
      expect(find.text('10+ Point Games'), findsOneWidget);

      // Records table.
      expect(find.text('Real NBA Records'), findsOneWidget);
      expect(find.text('Longest winning streak'), findsOneWidget);
      expect(find.text('to go'), findsNothing); // rendered as "N games to go"
      expect(find.textContaining('to go'), findsWidgets);

      // Leaderboards hero with the "on N boards" summary (the 12-point
      // game doesn't crack any board).
      expect(find.text('Best Single Games'), findsOneWidget);
      expect(find.textContaining("You're currently on"), findsNothing);
    });

    testWidgets('highlights a broken record with the BROKEN badge', (
      tester,
    ) async {
      await StorageService.writeJson(StorageService.gamesKey, [
        for (var i = 1; i <= 34; i++)
          _game(
            won: true,
            points: 32,
            date: '2026-01-${i.toString().padLeft(2, '0')}',
            gameNumber: i,
          ),
      ]);
      await _pumpRecords(tester);

      expect(find.text('🏆 BROKEN'), findsNWidgets(3));
    });

    testWidgets('shows top-20 performance highlighted on a leaderboard', (
      tester,
    ) async {
      await StorageService.writeJson(StorageService.gamesKey, [
        _game(points: 64, date: '2026-02-01'),
      ]);
      await _pumpRecords(tester);

      // Player row flagged on the single-game points board.
      expect(find.text('You'), findsOneWidget);
      expect(find.textContaining("You're on this board"), findsOneWidget);
    });

    testWidgets('absent and playoff games never reach the boards', (
      tester,
    ) async {
      await StorageService.writeJson(StorageService.gamesKey, [
        _game(points: 99, isAbsent: true, date: '2026-02-01'),
        _game(points: 99, gameType: GameType.playoffs, date: '2026-02-02'),
      ]);
      await _pumpRecords(tester);

      expect(find.text('You'), findsNothing);
      expect(find.text('🏆 BROKEN'), findsNothing);
    });
  });

  group('RecordsScreen refresh', () {
    testWidgets('pull-to-refresh reloads stored games', (tester) async {
      await StorageService.writeJson(StorageService.gamesKey, [
        _game(points: 30, won: true, date: '2026-01-01'),
      ]);
      await _pumpRecords(tester);
      expect(find.text('Career Top Streaks'), findsOneWidget);

      await StorageService.writeJson(StorageService.gamesKey, [
        _game(points: 30, won: true, date: '2026-01-01'),
        for (var i = 2; i <= 35; i++)
          _game(
            won: true,
            points: 32,
            date: '2026-01-${i.toString().padLeft(2, '0')}',
            gameNumber: i,
          ),
      ]);
      tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show();
      await tester.pumpAndSettle();

      expect(find.text('🏆 BROKEN'), findsNWidgets(3));
    });
  });
}
