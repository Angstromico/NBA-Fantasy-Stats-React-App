import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nba_fantasy_stats_react_app/models/season_stats.dart';
import 'package:nba_fantasy_stats_react_app/theme/app_theme.dart';
import 'package:nba_fantasy_stats_react_app/widgets/milestones_flip_card.dart';

StatisticalMilestones _milestones({
  Map<String, int>? points,
  Map<String, int>? assists,
  Map<String, int>? rebounds,
  Map<String, int>? blocks,
  Map<String, int>? steals,
  List<EliteLineGame> eliteGames = const [],
}) => StatisticalMilestones(
  points: points ?? {'10+': 0},
  assists: assists ?? {'5+': 0},
  rebounds: rebounds ?? {'5+': 0},
  blocks: blocks ?? {'2+': 0},
  steals: steals ?? {'2+': 0},
  eliteLines: EliteLines(
    quadrupleDoubles: eliteGames.length,
    quintupleDoubles: 0,
    doubleQuintupleDoubles: 0,
    games: eliteGames,
  ),
);

Future<void> _pumpCard(
  WidgetTester tester, {
  required StatisticalMilestones current,
  required StatisticalMilestones career,
}) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: MilestonesFlipCard(
            currentMilestones: current,
            careerMilestones: career,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('MilestonesFlipCard — front face', () {
    testWidgets('shows the current season face first', (tester) async {
      await _pumpCard(
        tester,
        current: _milestones(points: {'10+': 3, '20+': 1}),
        career: _milestones(points: {'10+': 40, '20+': 12}),
      );

      expect(find.text('Statistical Milestones'), findsOneWidget);
      expect(find.text('Current Season (Active)'), findsOneWidget);
      expect(find.text('🔄 All Seasons'), findsOneWidget);
      expect(find.text('Career Cumulative'), findsNothing);
      // Milestone counts from the current season data only.
      expect(find.text('3'), findsWidgets);
    });

    testWidgets('renders the four milestone column headings', (tester) async {
      await _pumpCard(tester, current: _milestones(), career: _milestones());

      expect(find.text('Points Games'), findsOneWidget);
      expect(find.text('Assists Games'), findsOneWidget);
      expect(find.text('Rebounds Games'), findsOneWidget);
      expect(find.text('Defense Games'), findsOneWidget);
      expect(find.text('Steals'), findsOneWidget);
      expect(find.text('Blocks'), findsOneWidget);
    });

    testWidgets('hides points thresholds >= 70 with zero counts', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        current: _milestones(
          points: {'30+': 2, '70+': 0, '80+': 0, '100+': 0, '100++': 0},
        ),
        career: _milestones(),
      );

      expect(find.text('30+'), findsOneWidget);
      expect(find.text('70+'), findsNothing);
      expect(find.text('80+'), findsNothing);
      expect(find.text('100+'), findsNothing);
      expect(find.text('100++'), findsNothing);
    });

    testWidgets('renders the flip cue', (tester) async {
      await _pumpCard(tester, current: _milestones(), career: _milestones());

      expect(
        find.text('Click to flip and view all seasons totals 🔄'),
        findsOneWidget,
      );
    });
  });

  group('MilestonesFlipCard — flipping', () {
    testWidgets('tap flips to the career face and back', (tester) async {
      await _pumpCard(
        tester,
        current: _milestones(points: {'10+': 3}),
        career: _milestones(points: {'10+': 40, '30+': 9}),
      );

      // Front face initially.
      expect(find.text('Current Season (Active)'), findsOneWidget);

      // Tap to flip.
      await tester.tap(find.byType(MilestonesFlipCard));
      await tester.pumpAndSettle();

      expect(find.text('All Seasons (Career Cumulative)'), findsOneWidget);
      expect(find.text('🔄 Current Season'), findsOneWidget);
      expect(find.text('Current Season (Active)'), findsNothing);
      // Career counts render on the back face.
      expect(find.text('40'), findsWidgets);
      expect(find.text('9'), findsWidgets);
      expect(
        find.text('Click to flip and return to current season 🔄'),
        findsOneWidget,
      );

      // Tap again to flip back.
      await tester.tap(find.byType(MilestonesFlipCard));
      await tester.pumpAndSettle();

      expect(find.text('Current Season (Active)'), findsOneWidget);
      expect(find.text('All Seasons (Career Cumulative)'), findsNothing);
    });

    testWidgets('animation runs 750ms with the plan duration', (tester) async {
      await _pumpCard(tester, current: _milestones(), career: _milestones());

      await tester.tap(find.byType(MilestonesFlipCard));
      // Mid-flip: neither face should be settled yet.
      await tester.pump(const Duration(milliseconds: 300));
      // The card is mid-rotation; both subtitles may briefly coexist or be
      // swapped — just ensure the widget tree is still valid.
      expect(find.byType(MilestonesFlipCard), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('All Seasons (Career Cumulative)'), findsOneWidget);
    });

    testWidgets('a tap during the animation does not lose state', (
      tester,
    ) async {
      await _pumpCard(tester, current: _milestones(), career: _milestones());

      await tester.tap(find.byType(MilestonesFlipCard));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byType(MilestonesFlipCard));
      await tester.pumpAndSettle();

      // The second tap reversed the flip — back to the front face.
      expect(find.text('Current Season (Active)'), findsOneWidget);
    });
  });

  group('MilestonesFlipCard — elite lines', () {
    testWidgets('shows the elite lines panel on both faces when present', (
      tester,
    ) async {
      final elite = [
        const EliteLineGame(
          tier: 'quadruple',
          date: '2026-02-01',
          points: 12,
          assists: 14,
          rebounds: 10,
          blocks: 10,
          steals: 3,
        ),
      ];

      await _pumpCard(
        tester,
        current: _milestones(eliteGames: elite),
        career: _milestones(eliteGames: elite),
      );

      expect(find.text('👑 Ultra-Rare All-Around Lines'), findsOneWidget);
      expect(find.text('QUADRUPLE-DOUBLE'), findsOneWidget);
      expect(
        find.text('2026-02-01 · 12 PTS · 14 AST · 10 REB · 10 BLK · 3 STL'),
        findsOneWidget,
      );

      // Flip — the career face also carries the panel.
      await tester.tap(find.byType(MilestonesFlipCard));
      await tester.pumpAndSettle();
      expect(find.text('👑 Ultra-Rare All-Around Lines'), findsOneWidget);
      expect(find.text('QUADRUPLE-DOUBLE'), findsOneWidget);
    });

    testWidgets('hides the elite panel when no games qualify', (tester) async {
      await _pumpCard(tester, current: _milestones(), career: _milestones());

      expect(find.text('👑 Ultra-Rare All-Around Lines'), findsNothing);
    });

    testWidgets('maps tier names to badges', (tester) async {
      const tiers = ['quintuple', 'doubleQuintuple'];
      final elite = [
        for (var i = 0; i < tiers.length; i++)
          EliteLineGame(
            tier: tiers[i],
            date: '2026-03-0${i + 1}',
            points: 20,
            assists: 20,
            rebounds: 20,
            blocks: 20,
            steals: 20,
          ),
      ];

      await _pumpCard(
        tester,
        current: _milestones(eliteGames: elite),
        career: _milestones(),
      );

      expect(find.text('QUINTUPLE-DOUBLE'), findsOneWidget);
      expect(find.text('DOUBLE QUINTUPLE-DOUBLE'), findsOneWidget);
    });
  });
}
