import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nba_fantasy_stats_react_app/screens/login_screen.dart';
import 'package:nba_fantasy_stats_react_app/theme/app_theme.dart';
import 'package:nba_fantasy_stats_react_app/utils/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpLogin(
  WidgetTester tester, {
  void Function(String username)? onAuthenticated,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      // GlassCard reads the GlassTheme extension, so the real app theme
      // must wrap the screen under test.
      theme: AppTheme.dark(),
      home: LoginScreen(
        onAuthenticated: onAuthenticated ?? (_) {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _toggleToRegister(WidgetTester tester) async {
  await tester.tap(find.text("Don't have an account? Register"));
  await tester.pump();
}

Future<void> _toggleToLogin(WidgetTester tester) async {
  await tester.tap(find.text('Already have an account? Login'));
  await tester.pump();
}

Future<void> _enterCredentials(
  WidgetTester tester, {
  required String username,
  required String password,
}) async {
  await tester.enterText(find.byKey(const Key('username_field')), username);
  await tester.enterText(find.byKey(const Key('password_field')), password);
  await tester.tap(find.byKey(const Key('submit_button')));
  // Register/login awaits SharedPreferences futures; let the chain complete.
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    StorageService.setInstance(await SharedPreferences.getInstance());
  });

  group('LoginScreen empty-field validation', () {
    testWidgets('shows error when fields are empty', (tester) async {
      await _pumpLogin(tester);
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pump();

      expect(
          find.text('Username and password cannot be empty.'), findsOneWidget);
    });
  });

  group('LoginScreen registration', () {
    testWidgets('registers a new user and switches to login mode',
        (tester) async {
      await _pumpLogin(tester);
      await _toggleToRegister(tester);
      await _enterCredentials(
        tester,
        username: 'manuel',
        password: 'secret123',
      );

      expect(
        find.text('Registration successful! You can now log in.'),
        findsOneWidget,
      );
      expect(find.text('Player Login'), findsOneWidget);
      expect(find.text('secret123'), findsNothing); // password stays masked
    });

    testWidgets('rejects duplicate username', (tester) async {
      await _pumpLogin(tester);
      await _toggleToRegister(tester);
      await _enterCredentials(tester, username: 'manuel', password: 'a');

      // Register a second account with the same username.
      await _toggleToRegister(tester);
      await _enterCredentials(tester, username: 'manuel', password: 'other');

      expect(find.text('Username already exists.'), findsOneWidget);
    });

    testWidgets('stores the user with a bcrypt hash, not plaintext',
        (tester) async {
      await _pumpLogin(tester);
      await _toggleToRegister(tester);
      await _enterCredentials(
          tester, username: 'testUser', password: 'plaintext');

      final raw = await StorageService.readList(StorageService.usersKey);
      expect(raw, hasLength(1));
      final stored = raw.first as Map;
      expect(stored['username'], 'testUser');
      expect(stored['hashedPassword'], isNot('plaintext'));
      expect(stored['hashedPassword'] as String, startsWith(r'$2'));
    });
  });

  group('LoginScreen login', () {
    testWidgets('logs in with valid credentials', (tester) async {
      String? loggedInAs;

      await _pumpLogin(tester, onAuthenticated: (u) => loggedInAs = u);
      await _toggleToRegister(tester);
      await _enterCredentials(tester, username: 'manuel', password: 'secret123');

      // Successful registration auto-switches to login mode.
      await _enterCredentials(tester, username: 'manuel', password: 'secret123');

      expect(loggedInAs, 'manuel');
    });

    testWidgets('rejects wrong password', (tester) async {
      String? loggedInAs;

      await _pumpLogin(tester, onAuthenticated: (u) => loggedInAs = u);
      await _toggleToRegister(tester);
      await _enterCredentials(tester, username: 'manuel', password: 'secret123');

      // Successful registration auto-switches to login mode.
      await _enterCredentials(
          tester, username: 'manuel', password: 'wrongPassword');

      expect(find.text('Invalid username or password.'), findsOneWidget);
      expect(loggedInAs, isNull);
    });

    testWidgets('rejects unknown username', (tester) async {
      String? loggedInAs;

      await _pumpLogin(tester, onAuthenticated: (u) => loggedInAs = u);
      await _enterCredentials(tester, username: 'ghost', password: 'whatever');

      expect(find.text('Invalid username or password.'), findsOneWidget);
      expect(loggedInAs, isNull);
    });
  });

  group('LoginScreen mode toggle', () {
    testWidgets('toggles between login and register headings', (tester) async {
      await _pumpLogin(tester);

      expect(find.text('Player Login'), findsOneWidget);

      await _toggleToRegister(tester);
      expect(find.text('Create Account'), findsOneWidget);

      await _toggleToLogin(tester);
      expect(find.text('Player Login'), findsOneWidget);
    });

    testWidgets('clears error message when toggling modes', (tester) async {
      await _pumpLogin(tester);
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pump();
      expect(find.text('Username and password cannot be empty.'),
          findsOneWidget);

      await _toggleToRegister(tester);

      expect(find.text('Username and password cannot be empty.'), findsNothing);
    });
  });
}
