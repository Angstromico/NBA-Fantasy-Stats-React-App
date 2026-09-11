import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nba_fantasy_stats_react_app/screens/main_shell.dart';
import 'package:nba_fantasy_stats_react_app/theme/app_theme.dart';

void main() {
  Future<void> pumpShell(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      // GlassCard reads the GlassTheme extension, so use the real theme.
      theme: AppTheme.dark(),
      home: const MainShell(username: 'manuel'),
    ));
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

    testWidgets('preserves tracker state across tab switches (IndexedStack)',
        (tester) async {
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
  });
}
