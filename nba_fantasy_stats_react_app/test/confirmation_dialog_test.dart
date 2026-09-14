import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nba_fantasy_stats_react_app/theme/app_theme.dart';
import 'package:nba_fantasy_stats_react_app/widgets/confirmation_dialog.dart';
import 'package:nba_fantasy_stats_react_app/widgets/glass_card.dart';

/// Host screen that opens the dialog via [ConfirmationDialog.show] and
/// records the resolved boolean through [result], so tests can assert the
/// returned value.
class _HostScreen extends StatelessWidget {
  const _HostScreen({
    required this.title,
    required this.message,
    required this.tone,
    required this.result,
    this.details,
    this.confirmLabel,
    this.cancelLabel,
    this.onConfirmed,
  });

  final String title;
  final String message;
  final ConfirmTone tone;
  final String? details;
  final String? confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirmed;
  final ValueChanged<bool> result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () async {
            final confirmed = await ConfirmationDialog.show(
              context,
              title: title,
              message: message,
              tone: tone,
              details: details,
              confirmLabel: confirmLabel ?? 'Confirm',
              cancelLabel: cancelLabel ?? 'Cancel',
              onConfirm: onConfirmed,
            );
            result(confirmed);
          },
          child: const Text('open'),
        ),
      ),
    );
  }
}

Future<void> _pumpHost(
  WidgetTester tester, {
  required ValueChanged<bool> result,
  String title = 'Reset Season',
  String message = 'This will erase all games in the current season.',
  ConfirmTone tone = ConfirmTone.danger,
  String? details,
  String? confirmLabel,
  String? cancelLabel,
  VoidCallback? onConfirmed,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: _HostScreen(
        title: title,
        message: message,
        tone: tone,
        details: details,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirmed: onConfirmed,
        result: result,
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConfirmationDialog.show', () {
    testWidgets('renders title, message, and default labels', (tester) async {
      await _pumpHost(tester, result: (_) {});

      expect(find.text('Reset Season'), findsOneWidget);
      expect(
        find.text('This will erase all games in the current season.'),
        findsOneWidget,
      );
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('shows the details box when details are provided', (
      tester,
    ) async {
      await _pumpHost(
        tester,
        result: (_) {},
        details: 'This action cannot be undone.',
      );

      expect(find.text('This action cannot be undone.'), findsOneWidget);
    });

    testWidgets('omits the details box without details', (tester) async {
      await _pumpHost(tester, result: (_) {});

      expect(find.text('This action cannot be undone.'), findsNothing);
    });

    testWidgets('renders the danger tone icon', (tester) async {
      await _pumpHost(tester, result: (_) {}, tone: ConfirmTone.danger);

      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets('renders the warning tone icon by default', (tester) async {
      await _pumpHost(tester, result: (_) {}, tone: ConfirmTone.warning);

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('renders the info tone icon', (tester) async {
      await _pumpHost(tester, result: (_) {}, tone: ConfirmTone.info);

      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });

    testWidgets('uses custom button labels', (tester) async {
      await _pumpHost(
        tester,
        result: (_) {},
        confirmLabel: 'Reset',
        cancelLabel: 'Stay on Current Season',
      );

      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('Stay on Current Season'), findsOneWidget);
      expect(find.text('Confirm'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('resolves true and fires onConfirm when confirmed', (
      tester,
    ) async {
      var resolved = false;
      var confirmedSideEffect = false;
      await _pumpHost(
        tester,
        result: (value) => resolved = value,
        onConfirmed: () => confirmedSideEffect = true,
      );

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(resolved, isTrue);
      expect(confirmedSideEffect, isTrue);
      // Dialog is gone after resolving.
      expect(find.byType(ConfirmationDialog), findsNothing);
    });

    testWidgets('does not fire onConfirm when cancelled', (tester) async {
      var resolved = true;
      var confirmedSideEffect = false;
      await _pumpHost(
        tester,
        result: (value) => resolved = value,
        onConfirmed: () => confirmedSideEffect = true,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(resolved, isFalse);
      expect(confirmedSideEffect, isFalse);
      expect(find.byType(ConfirmationDialog), findsNothing);
    });

    testWidgets('resolves false when the barrier is tapped', (tester) async {
      var resolved = true;
      await _pumpHost(tester, result: (value) => resolved = value);

      // Tap the top-left of the screen, outside the dialog content.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(resolved, isFalse);
      expect(find.byType(ConfirmationDialog), findsNothing);
    });
  });

  group('ConfirmationDialog tone styling', () {
    testWidgets('tints the details box with the tone accent', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(
            body: ConfirmationDialog(
              title: 'Reset Season',
              message: 'Erase everything?',
              tone: ConfirmTone.danger,
              details: 'This action cannot be undone.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final detailsFinder = find.text('This action cannot be undone.');
      final context = tester.element(detailsFinder);
      final accent = Theme.of(context).colorScheme.error;
      final container = tester.widget<Container>(
        find
            .ancestor(of: detailsFinder, matching: find.byType(Container))
            .first,
      );
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.color, accent.withValues(alpha: 0.08));
      expect(
        decoration.border,
        Border.all(color: accent.withValues(alpha: 0.25)),
      );
    });

    testWidgets('renders inside a glass card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(
            body: ConfirmationDialog(
              title: 'Reset Season',
              message: 'Erase everything?',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GlassCard), findsOneWidget);
    });

    testWidgets('colors the confirm button with the tone accent', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(
            body: ConfirmationDialog(
              title: 'Reset Season',
              message: 'Erase everything?',
              tone: ConfirmTone.warning,
              confirmLabel: 'Reset',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Reset'),
      );
      final style = button.style!;
      expect(style.backgroundColor?.resolve({}), Colors.amber);
    });
  });
}
