import 'package:flutter/material.dart';

/// Records & leaderboards — placeholder scaffold for Step 5's navigation
/// shell.
///
/// Step 10 (Records & Leaderboards Screen) replaces this file's build with
/// the full records layout from `RecordsDisplay.tsx`.
class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Records')),
      body: Center(
        child: Text('Coming in Step 10 — signed in as $username'),
      ),
    );
  }
}
