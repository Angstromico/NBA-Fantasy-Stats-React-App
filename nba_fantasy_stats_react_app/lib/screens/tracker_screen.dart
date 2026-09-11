import 'package:flutter/material.dart';

/// Game tracker — placeholder scaffold for Step 5's navigation shell.
///
/// Step 7 (Game Tracker Screen) replaces this file's build with the full
/// stat-logging form from `GameForm.tsx`.
class TrackerScreen extends StatelessWidget {
  const TrackerScreen({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Tracker')),
      body: Center(
        child: Text('Coming in Step 7 — signed in as $username'),
      ),
    );
  }
}
