import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nba_fantasy_stats_react_app/models/enums.dart';
import 'package:nba_fantasy_stats_react_app/models/game_stats.dart';
import 'package:nba_fantasy_stats_react_app/screens/tracker_screen.dart';
import 'package:nba_fantasy_stats_react_app/theme/app_theme.dart';
import 'package:nba_fantasy_stats_react_app/utils/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpTracker(WidgetTester tester) async {
  // Tall surface so the entire form (button included) is on-screen and
  // tappable without scrolling in the 800x600 default test viewport.
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark(),
    home: const TrackerScreen(username: 'manuel'),
  ));
  await tester.pumpAndSettle();
}

Future<void> _enterStat(
  WidgetTester tester,
  String label,
  String value,
) async {
  await tester.enterText(find.widgetWithText(TextField, label), value);
}

Future<List<GameStats>> _storedGames() async {
  final raw = await StorageService.readList(StorageService.gamesKey);
  return raw.map((j) => GameStats.fromJson(j as Map<String, dynamic>)).toList();
}

Future<void> _logGame(WidgetTester tester) async {
  await tester.tap(find.text('Log Game'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    StorageService.setInstance(await SharedPreferences.getInstance());
  });

  group('TrackerScreen stat logging', () {
    testWidgets('logs a basic game and resets the form', (tester) async {
      await _pumpTracker(tester);

      await _enterStat(tester, 'Points', '25');
      await _enterStat(tester, 'Assists', '6');
      await _enterStat(tester, 'Minutes', '34');
      await _logGame(tester);

      final games = await _storedGames();
      expect(games, hasLength(1));
      expect(games.first.points, 25);
      expect(games.first.assists, 6);
      expect(games.first.minutes, 34);
      expect(games.first.won, isFalse);
      expect(games.first.isDoubleDouble, isFalse);
      expect(find.textContaining('1 logged'), findsOneWidget);

      // Form resets after logging.
      final ptsField =
          tester.widget<TextField>(find.widgetWithText(TextField, 'Points'));
      expect(ptsField.controller!.text, isEmpty);
    });

    testWidgets('derives double-double from two 10+ categories',
        (tester) async {
      await _pumpTracker(tester);

      await _enterStat(tester, 'Points', '22');
      await _enterStat(tester, 'Rebounds', '11');
      await _logGame(tester);

      final games = await _storedGames();
      expect(games.first.isDoubleDouble, isTrue);
      expect(games.first.isTripleDouble, isFalse);
    });

    testWidgets('derives triple-double from three 10+ categories',
        (tester) async {
      await _pumpTracker(tester);

      await _enterStat(tester, 'Points', '30');
      await _enterStat(tester, 'Assists', '10');
      await _enterStat(tester, 'Rebounds', '12');
      await _logGame(tester);

      final games = await _storedGames();
      expect(games.first.isDoubleDouble, isTrue);
      expect(games.first.isTripleDouble, isTrue);
    });

    testWidgets('buzzer beater forces the win flag on', (tester) async {
      await _pumpTracker(tester);

      await _enterStat(tester, 'Points', '18');
      // Turn "Won" off, then enable the buzzer beater — the win must lock on.
      await tester.tap(find.text('Won'));
      await tester.pump();
      await tester.tap(find.text('Buzzer Beater'));
      await tester.pump();

      final wonSwitch = tester.widget<Switch>(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Won'),
          matching: find.byType(Switch),
        ),
      );
      expect(wonSwitch.value, isTrue);

      await _logGame(tester);

      final games = await _storedGames();
      expect(games.first.isBuzzerBeater, isTrue);
      expect(games.first.won, isTrue);
    });

    testWidgets('selecting an absence reason zeroes all stats',
        (tester) async {
      await _pumpTracker(tester);

      await _enterStat(tester, 'Points', '25');
      await _enterStat(tester, 'Assists', '8');

      // Open the absence dropdown and pick "injury" (labels mirror the
      // React app's lowercase rendering of snake_case values).
      await tester
          .tap(find.byType(DropdownButtonFormField<AbsenceType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('injury').last);
      await tester.pumpAndSettle();

      // The zeroed fields are what gets stored when submitting.
      await _logGame(tester);

      final games = await _storedGames();
      expect(games.first.isAbsent, isTrue);
      expect(games.first.absenceType, AbsenceType.injury);
      expect(games.first.points, 0);
      expect(games.first.assists, 0);
      expect(games.first.isDoubleDouble, isFalse);
      expect(games.first.isBuzzerBeater, isFalse);
    });

    testWidgets('increments game number across logged games', (tester) async {
      await _pumpTracker(tester);

      for (var i = 0; i < 3; i++) {
        await _enterStat(tester, 'Points', '${10 + i}');
        await _logGame(tester);
      }

      final games = await _storedGames();
      expect(games, hasLength(3));
      expect(games.map((g) => g.gameNumber), [1, 2, 3]);
    });
  });

  group('TrackerScreen game type', () {
    testWidgets('switches between regular and playoffs', (tester) async {
      await _pumpTracker(tester);

      await tester.tap(find.text('Playoffs'));
      await tester.pump();
      await _enterStat(tester, 'Points', '20');
      await _logGame(tester);

      final games = await _storedGames();
      expect(games.first.gameType, GameType.playoffs);
    });
  });
}
