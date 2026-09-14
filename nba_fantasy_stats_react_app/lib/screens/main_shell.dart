import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats_react_app/models/game_stats.dart';
import 'package:nba_fantasy_stats_react_app/screens/records_screen.dart';
import 'package:nba_fantasy_stats_react_app/screens/summary_screen.dart';
import 'package:nba_fantasy_stats_react_app/screens/tracker_screen.dart';

/// Post-login navigation shell — replaces the React app's `AppView` union
/// type (`tracker | summary | records`) with a bottom `NavigationBar`.
/// The shell forwards the app-level team/season state and game callbacks
/// between [AppHomePage] and the tab screens so selection survives tab
/// switches (IndexedStack keeps each tab alive).
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.username,
    this.selectedTeam = '',
    this.selectedSeason = '',
    this.onTeamChange,
    this.onSeasonChange,
    this.onResetSeason,
    this.onGamesLogged,
  });

  final String username;
  final String selectedTeam;
  final String selectedSeason;
  final void Function(String team)? onTeamChange;
  final void Function(String season)? onSeasonChange;
  final void Function(String season)? onResetSeason;
  final void Function(List<GameStats> games)? onGamesLogged;

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

  @override
  Widget build(BuildContext context) {
    final screens = [
      TrackerScreen(
        username: widget.username,
        selectedTeam: widget.selectedTeam,
        selectedSeason: widget.selectedSeason,
        onTeamChange: widget.onTeamChange,
        onSeasonChange: widget.onSeasonChange,
        onResetSeason: widget.onResetSeason,
        onGamesLogged: widget.onGamesLogged,
      ),
      SummaryScreen(username: widget.username),
      RecordsScreen(username: widget.username),
    ];

    final wide = MediaQuery.of(context).size.width > 900;

    final body = wide
        ? Row(
            children: [
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.sports_basketball_outlined),
                    selectedIcon: Icon(Icons.sports_basketball),
                    label: Text('Tracker'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.bar_chart_outlined),
                    selectedIcon: Icon(Icons.bar_chart),
                    label: Text('Summary'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.emoji_events_outlined),
                    selectedIcon: Icon(Icons.emoji_events),
                    label: Text('Records'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: IndexedStack(index: _index, children: screens),
              ),
            ],
          )
        : Scaffold(
            // IndexedStack keeps each tab's state alive across tab switches,
            // the standard Android pattern for bottom navigation.
            body: IndexedStack(index: _index, children: screens),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: _destinations,
            ),
          );

    return wide ? Scaffold(body: body) : body;
  }
}
