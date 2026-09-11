import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats_react_app/screens/records_screen.dart';
import 'package:nba_fantasy_stats_react_app/screens/summary_screen.dart';
import 'package:nba_fantasy_stats_react_app/screens/tracker_screen.dart';

/// Post-login navigation shell — replaces the React app's `AppView` union
/// type (`tracker | summary | records`) with a bottom `NavigationBar`
/// (Step 5 of FLUTTER_PLAN.md).
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.username});

  final String username;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.sports_basketball_outlined),
      selectedIcon: Icon(Icons.sports_basketball),
      label: 'Tracker',
    ),
    NavigationDestination(
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart),
      label: 'Summary',
    ),
    NavigationDestination(
      icon: Icon(Icons.emoji_events_outlined),
      selectedIcon: Icon(Icons.emoji_events),
      label: 'Records',
    ),
  ];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      TrackerScreen(username: widget.username),
      SummaryScreen(username: widget.username),
      RecordsScreen(username: widget.username),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps each tab's state alive across tab switches,
      // the standard Android pattern for bottom navigation.
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _destinations,
      ),
    );
  }
}
