import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nba_fantasy_stats_react_app/models/enums.dart';
import 'package:nba_fantasy_stats_react_app/models/game_stats.dart';
import 'package:nba_fantasy_stats_react_app/screens/summary_screen.dart';
import 'package:nba_fantasy_stats_react_app/theme/app_theme.dart';
import 'package:nba_fantasy_stats_react_app/utils/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

GameStats _game({
  required String season,
  bool won = false,
  int points = 0,
  GameType gameType = GameType.regular,
  bool isAbsent = false,
  bool isDoubleDouble = false,
  bool isBuzzerBeater = false,
}) =>
    GameStats(
      id: 'g_${season}_${points}_${won}_$gameType',
      date: '2026-01-15',
      team: 'MyTeam',
      opponent: 'Rivals',
      gameNumber: 1,
      gameType: gameType,
      absenceType: isAbsent ? AbsenceType.rest : AbsenceType.none,
      isAbsent: isAbsent,
      points: isAbsent ? 0 : points,
      assists: 0,
      rebounds: 0,
      blocks: 0,
      steals: 0,
      minutes: 0,
      won: won,
      isDoubleDouble: isDoubleDouble,
      isTripleDouble: false,
      isBuzzerBeater: isBuzzerBeater,
      season: season,
    );

Future<void> _pumpSummary(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark(),
    home: const SummaryScreen(username: 'manuel'),
  ));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    StorageService.setInstance(await SharedPreferences.getInstance());
  });

  group('SummaryScreen empty state', () {
    testWidgets('shows the empty state with no games', (tester) async {
      await _pumpSummary(tester);

      expect(find.text('No games logged yet'), findsOneWidget);
      expect(find.textContaining('tracker'), findsOneWidget);
    });
  });

  group('SummaryScreen with games', () {
    testWidgets('shows hero player record and KPI tiles', (tester) async {
      await StorageService.writeJson(StorageService.gamesKey, [
        _game(season: '2025-26', won: true, points: 25).toJson(),
        _game(season: '2025-26', won: false, points: 12).toJson(),
        _game(season: '2024-25', won: true, points: 30).toJson(),
      ]);
      await _pumpSummary(tester);

      // Hero.
      expect(find.text('Player Record'), findsWidgets);
      expect(find.text('2-1'), findsWidgets); // player record 2-1

      // KPI tiles.
      expect(find.text('Logged Games'), findsOneWidget);
      expect(find.text('Games Played'), findsOneWidget);
      expect(find.text('Games Missed'), findsOneWidget);
      expect(find.text('Team Record'), findsWidgets);
      expect(find.text('Career PPG'), findsOneWidget);
      expect(find.text('Best PPG Season'), findsOneWidget);
      expect(find.text('Buzzer Beaters'), findsWidgets);
    });

    testWidgets('renders one card per season plus career', (tester) async {
      await StorageService.writeJson(StorageService.gamesKey, [
        _game(season: '2025-26', won: true, points: 25).toJson(),
        _game(season: '2024-25', won: false, points: 12).toJson(),
      ]);
      await _pumpSummary(tester);

      // Season labels + career label, most recent season first.
      expect(find.text('2025-26'), findsOneWidget);
      expect(find.text('2024-25'), findsOneWidget);
      expect(find.text('Career Total'), findsOneWidget);

      // Career chip marks the career row.
      expect(find.text('Career'), findsOneWidget);
    });

    testWidgets('splits regular and playoff records per season',
        (tester) async {
      await StorageService.writeJson(StorageService.gamesKey, [
        _game(season: '2025-26', won: true, points: 20).toJson(),
        _game(season: '2025-26', won: true, points: 22, gameType: GameType.playoffs).toJson(),
        _game(season: '2025-26', won: false, points: 15, gameType: GameType.playoffs).toJson(),
      ]);
      await _pumpSummary(tester);

      expect(find.text('Regular'), findsWidgets);
      expect(find.text('Playoffs'), findsWidgets);
      expect(find.text('1-0'), findsWidgets); // regular record
    });

    testWidgets('highlights best scoring season', (tester) async {
      await StorageService.writeJson(StorageService.gamesKey, [
        _game(season: '2025-26', won: true, points: 30).toJson(),
        _game(season: '2024-25', won: true, points: 10).toJson(),
      ]);
      await _pumpSummary(tester);

      expect(find.text('2025-26 (30.0)'), findsOneWidget);
    });

    testWidgets('shows missed record when games were absent', (tester) async {
      await StorageService.writeJson(StorageService.gamesKey, [
        _game(season: '2025-26', isAbsent: true, won: true).toJson(),
      ]);
      await _pumpSummary(tester);

      expect(find.text('1-0'), findsWidgets); // missed record 1-0
      expect(find.text('Absent'), findsWidgets);
    });

    testWidgets('excludes absent games from averages', (tester) async {
      await StorageService.writeJson(StorageService.gamesKey, [
        _game(season: '2025-26', points: 30).toJson(),
        _game(season: '2025-26', isAbsent: true, points: 0).toJson(),
      ]);
      await _pumpSummary(tester);

      // PPG over played games only (30/1) — rendered in the KPI tile and
      // both summary cards.
      expect(find.text('30.0'), findsNWidgets(3));
    });
  });

  group('SummaryScreen refresh', () {
    testWidgets('pull-to-refresh reloads stored games', (tester) async {
      await StorageService.writeJson(StorageService.gamesKey, [
        _game(season: '2025-26', won: true, points: 25).toJson(),
      ]);
      await _pumpSummary(tester);
      expect(find.text('Logged Games'), findsOneWidget);

      // Add a new game and trigger the refresh indicator deterministically
      // (gesture simulation is flaky for arming RefreshIndicator).
      await StorageService.writeJson(StorageService.gamesKey, [
        _game(season: '2025-26', won: true, points: 25).toJson(),
        _game(season: '2025-26', won: false, points: 10).toJson(),
      ]);
      tester.state<RefreshIndicatorState>(
        find.byType(RefreshIndicator),
      ).show();
      await tester.pumpAndSettle();

      expect(find.text('Logged Games'), findsOneWidget);
      expect(find.text('2'), findsWidgets); // logged games tile updated
    });
  });
}
