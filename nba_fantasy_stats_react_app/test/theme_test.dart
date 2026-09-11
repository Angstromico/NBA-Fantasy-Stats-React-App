import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nba_fantasy_stats_react_app/screens/login_screen.dart';
import 'package:nba_fantasy_stats_react_app/theme/app_theme.dart';
import 'package:nba_fantasy_stats_react_app/widgets/glass_card.dart';

Widget _wrap(Widget child, {ThemeData? theme}) =>
    MaterialApp(theme: theme ?? AppTheme.dark(), home: Scaffold(body: child));

void main() {
  group('GlassTheme extension', () {
    test('dark theme carries the dark-mode CSS palette', () {
      final glass = AppTheme.dark().extension<GlassTheme>()!;

      expect(glass.glassColor, const Color(0xB31E293B)); // rgba(30,41,59,.7)
      expect(glass.glassBorder, const Color(0x1AFFFFFF)); // rgba(255,255,255,.1)
      expect(glass.blurSigma, 12);
      expect(glass.borderRadius, 20);
    });

    test('light theme carries the light-mode CSS palette', () {
      final glass = AppTheme.light().extension<GlassTheme>()!;

      expect(glass.glassColor, const Color(0xB3FFFFFF)); // rgba(255,255,255,.7)
      expect(glass.glassBorder, const Color(0x1A000000)); // rgba(0,0,0,.1)
      expect(glass.blurSigma, 12);
    });

    test('copyWith overrides only given fields', () {
      const original = GlassTheme(
        glassColor: Color(0xB31E293B),
        glassBorder: Color(0x1AFFFFFF),
        blurSigma: 12,
        borderRadius: 20,
        shadowColor: Color(0x5E000000),
        shadowOffset: Offset(0, 8),
        shadowBlurRadius: 32,
      );
      final updated = original.copyWith(blurSigma: 24);

      expect(updated.blurSigma, 24);
      expect(updated.glassColor, original.glassColor);
      expect(updated.borderRadius, original.borderRadius);
    });

    test('lerp blends colors and doubles between themes', () {
      const a = GlassTheme(
        glassColor: Color(0xB31E293B),
        glassBorder: Color(0x1AFFFFFF),
        blurSigma: 12,
        borderRadius: 20,
        shadowColor: Color(0x5E000000),
        shadowOffset: Offset(0, 8),
        shadowBlurRadius: 32,
      );
      const b = GlassTheme(
        glassColor: Color(0xB3FFFFFF),
        glassBorder: Color(0x1A000000),
        blurSigma: 20,
        borderRadius: 24,
        shadowColor: Color(0x121F2687),
        shadowOffset: Offset(0, 4),
        shadowBlurRadius: 16,
      );
      final mid = a.lerp(b, 0.5);

      expect(mid.blurSigma, 16);
      expect(mid.borderRadius, 22);
      expect(mid.glassColor, isNot(a.glassColor));
      expect(mid.glassColor, isNot(b.glassColor));
      expect(a.lerp(null, 0.5), a);
    });
  });

  group('AppTheme color scheme', () {
    test('dark scheme matches body.dark-mode CSS variables', () {
      final scheme = AppTheme.dark().colorScheme;

      expect(scheme.primary, const Color(0xFF38BDF8)); // --accent-primary
      expect(scheme.secondary, const Color(0xFF818CF8)); // --accent-secondary
      expect(scheme.tertiary, const Color(0xFFF472B6)); // --accent-tertiary
      expect(scheme.error, const Color(0xFFF87171)); // --accent-error
      expect(scheme.surface, const Color(0xFF0F172A)); // --bg-dark
    });

    test('light scheme matches :root CSS variables', () {
      final scheme = AppTheme.light().colorScheme;

      expect(scheme.primary, const Color(0xFF0284C7));
      expect(scheme.secondary, const Color(0xFF4F46E5));
      expect(scheme.tertiary, const Color(0xFFDB2777));
      expect(scheme.error, const Color(0xFFDC2626));
      expect(scheme.surface, const Color(0xFFF1F5F9));
    });
  });

  group('GlassCard rendering', () {
    testWidgets('applies GlassTheme radius and blur inside a themed tree',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const GlassCard(child: SizedBox(width: 100, height: 100)),
      ));

      final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clip.borderRadius, BorderRadius.circular(20));

      final backdrop = tester.widget<BackdropFilter>(
        find.byType(BackdropFilter),
      );
      expect(backdrop.filter, isA<ImageFilter>());
    });

    testWidgets('applies custom padding', (tester) async {
      await tester.pumpWidget(_wrap(
        const GlassCard(
          padding: EdgeInsets.all(48),
          child: SizedBox(width: 10, height: 10),
        ),
      ));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(GlassCard),
          matching: find.byType(Container),
        ),
      );
      expect(container.padding, const EdgeInsets.all(48));
    });
  });

  group('LoginScreen under GlassCard theme', () {
    testWidgets('renders correctly with dark theme applied',
        (tester) async {
      await tester.pumpWidget(_wrap(
        LoginScreen(onAuthenticated: (_) {}),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Player Login'), findsOneWidget);
      expect(find.byType(GlassCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
