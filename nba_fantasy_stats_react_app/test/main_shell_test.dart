import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nba_fantasy_stats_react_app/models/game_stats.dart';
import 'package:nba_fantasy_stats_react_app/screens/main_shell.dart';
import 'package:nba_fantasy_stats_react_app/theme/app_theme.dart';
import 'package:nba_fantasy_stats_react_app/utils/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // The shell renders real screens that read storage.
    SharedPreferences.setMockInitialValues({});
    StorageService.setInstance(await SharedPreferences.getInstance());
  });

  Future<void> pumpShell(
    WidgetTester tester, {
    String team = 'Boston Celtics',
    String season = '2024-2025',
  }) async {
    // Tall surface so the tracker form (and its Log Game button) fits
    // on-screen alongside the shell header and bottom navigation bar.
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Mirror the real app wiring: the shell's parent (AppHomePage in
    // production) owns the games list and receives every save.
    var games = <GameStats>[];
    await tester.pumpWidget(
      MaterialApp(
        // GlassCard reads the GlassTheme extension, so use the real theme.
        theme: AppTheme.dark(),
        home: StatefulBuilder(
          builder: (context, setState) {
            return MainShell(
              username: 'manuel',
              selectedTeam: team,
              selectedSeason: season,
              games: games,
              onGamesLogged: (newGames) =>
                  setState(() => games = [...games, ...newGames]),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('MainShell navigation', () {
    testWidgets('shows the tracker tab by default', (tester) async {
      await pumpShell(tester);

      expect(find.text('Game Tracker'), findsOneWidget);
      expect(find.text('Season Summary'), findsNothing);
      expect(find.text('Records'), findsOneWidget); // tab label
    });

    testWidgets('switches to the summary tab', (tester) async {
      await pumpShell(tester);

      await tester.tap(find.text('Summary'));
      await tester.pumpAndSettle();

      expect(find.text('Season Summary'), findsOneWidget);
      expect(find.text('Game Tracker'), findsNothing);
    });

    testWidgets('switches to the records tab', (tester) async {
      await pumpShell(tester);

      await tester.tap(find.text('Records'));
      await tester.pumpAndSettle();

      // Two matches: the tab label and the records screen AppBar title.
      expect(find.text('Records'), findsNWidgets(2));
      expect(find.text('Game Tracker'), findsNothing);
      expect(find.text('Season Summary'), findsNothing);
    });

    testWidgets('preserves tracker state across tab switches (IndexedStack)', (
      tester,
    ) async {
      await pumpShell(tester);

      // Both screens stay in the tree; IndexedStack only hides the inactive
      // ones, so the tracker AppBar still exists while Summary is visible.
      await tester.tap(find.text('Summary'));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) => w is AppBar && w.title is Text,
          description: 'tracker AppBar retained in IndexedStack',
        ),
        findsAtLeastNWidgets(1),
      );

      await tester.tap(find.text('Tracker'));
      await tester.pumpAndSettle();
      expect(find.text('Game Tracker'), findsOneWidget);
    });

    testWidgets('passes the username to tab screens', (tester) async {
      await pumpShell(tester);

      expect(find.textContaining('manuel'), findsOneWidget);
    });

    testWidgets('summary and records reflect games logged on the tracker', (
      tester,
    ) async {
      await pumpShell(tester);

      // Log a game on the tracker tab.
      await tester.enterText(find.widgetWithText(TextField, 'Points'), '25');
      await tester.tap(find.text('Log Game'));
      await tester.pumpAndSettle();

      // The summary tab (kept alive in the IndexedStack) must show the
      // logged game without any manual refresh — regression for the
      // "no games logged" bug where tabs kept stale empty state.
      await tester.tap(find.text('Summary'));
      await tester.pumpAndSettle();
      expect(find.text('No games logged yet'), findsNothing);

      // Same for the records tab.
      await tester.tap(find.text('Records'));
      await tester.pumpAndSettle();
      expect(find.text('No games logged yet'), findsNothing);
    });
  });
}
