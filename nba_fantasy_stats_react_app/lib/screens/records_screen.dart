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
  const RecordsScreen({super.key, required this.username});

  final String username;

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  List<GameStats> _games = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
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
    setState(() {
      _games = games;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Records')),
      body: RefreshIndicator(
        onRefresh: _loadGames,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            RecordsDisplay(stats: _games, congrats: const []),
            const SizedBox(height: 16),
            AllTimeLeaderboards(stats: _games, playerName: widget.username),
          ],
        ),
      ),
    );
  }
}
