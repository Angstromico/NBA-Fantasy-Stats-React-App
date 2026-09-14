import 'package:flutter_test/flutter_test.dart';
import 'package:nba_fantasy_stats_react_app/app.dart';
import 'package:nba_fantasy_stats_react_app/utils/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App boots to the login screen when logged out', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    StorageService.setInstance(await SharedPreferences.getInstance());

    await tester.pumpWidget(const NbaFantasyApp());
    await tester.pumpAndSettle();

    // The login gate from App.tsx (`if (!currentUser) return <Login … />`).
    expect(find.text('Player Login'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
