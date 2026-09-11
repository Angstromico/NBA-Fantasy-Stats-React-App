import 'package:flutter/material.dart';

/// Season summary — placeholder scaffold for Step 5's navigation shell.
///
/// Step 9 (Season Summary Screen) replaces this file's build with the full
/// stat overview from `StatsSummaryPage.tsx`.
class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Season Summary')),
      body: Center(
        child: Text('Coming in Step 9 — signed in as $username'),
      ),
    );
  }
}
