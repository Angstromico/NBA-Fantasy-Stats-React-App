import 'package:flutter_test/flutter_test.dart';

import 'package:nba_fantasy_stats_react_app/app.dart';

void main() {
  testWidgets('App renders placeholder screen', (WidgetTester tester) async {
    await tester.pumpWidget(const NbaFantasyApp());

    expect(find.text('NBA Fantasy Stats'), findsOneWidget);
  });
}
