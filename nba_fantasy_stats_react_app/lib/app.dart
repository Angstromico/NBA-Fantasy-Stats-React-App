import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats_react_app/theme/app_theme.dart';

class NbaFantasyApp extends StatelessWidget {
  const NbaFantasyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NBA Fantasy Stats',
      debugShowCheckedModeBanner: false,
      // Dark mode first — the React app defaults to `body.dark-mode`.
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const Scaffold(body: Center(child: Text('NBA Fantasy Stats'))),
    );
  }
}
