import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats_react_app/models/game_stats.dart';
import 'package:nba_fantasy_stats_react_app/utils/storage_service.dart';
import 'package:nba_fantasy_stats_react_app/widgets/all_time_leaderboards.dart';
import 'package:nba_fantasy_stats_react_app/widgets/records_display.dart';

/// Records & leaderboards — Dart port of `RecordsDisplay.tsx` +
/// `AllTimeLeaderboards.tsx` (Step 10 of FLUTTER_PLAN.md). Loads the logged
/// games from storage and renders the record-chase view and the all-time
/// top-20 leaderboard boards.
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key, required this.username, this.games});

  final String username;

  /// The live games list from the app shell (the React app's `stats`
  /// prop). When provided it always wins over storage, so the records view
  /// updates the moment a game is logged. Standalone/tests may omit it and
  /// the screen falls back to reading storage itself.
  final List<GameStats>? games;

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  List<GameStats> _games = [];

  @override
  void initState() {
    super.initState();
    if (widget.games != null) {
      // The shell already pushed the live list — no storage round-trip.
      _games = widget.games!;
    } else {
      _loadGames();
    }
  }

  Future<void> _loadGames() async {
    // When the shell pushes the live games list, storage is never read.
    if (widget.games != null) {
      if (!mounted) return;
      setState(() => _games = widget.games!);
      return;
    }
    List<GameStats> games;
    try {
      final raw = await StorageService.readList(StorageService.gamesKey);
      games = raw
          .map((j) => GameStats.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Storage or parse failure must never leave the screen loading.
      games = [];
    }
    if (!mounted) return;
    setState(() => _games = games);
  }

  @override
  void didUpdateWidget(RecordsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-sync whenever the shell pushes a new games list (e.g. after
    // logging a game) — the IndexedStack keeps this state object alive, so
    // prop changes arrive here rather than through initState.
    if (!identical(oldWidget.games, widget.games)) {
      setState(() => _games = widget.games ?? _games);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Records')),
      body: RefreshIndicator(
        onRefresh: _loadGames,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Wide screens read better with a centered reading column; on
            // phones the cards use the full width.
            final wide = constraints.maxWidth > 900;
            final content = ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                RecordsDisplay(stats: _games, congrats: const []),
                const SizedBox(height: 16),
                AllTimeLeaderboards(stats: _games, playerName: widget.username),
              ],
            );
            return wide
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: content,
                    ),
                  )
                : content;
          },
        ),
      ),
    );
  }
}
