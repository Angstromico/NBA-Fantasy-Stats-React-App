import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats_react_app/models/enums.dart';
import 'package:nba_fantasy_stats_react_app/models/game_stats.dart';
import 'package:nba_fantasy_stats_react_app/utils/stats_calculations.dart';
import 'package:nba_fantasy_stats_react_app/utils/storage_service.dart';
import 'package:nba_fantasy_stats_react_app/widgets/glass_card.dart';
import 'package:nba_fantasy_stats_react_app/widgets/stat_row.dart';

/// Season summary replicating `StatsSummaryPage.tsx` (Step 9 of
/// FLUTTER_PLAN.md): per-season rows compared against a career total, with
/// records, availability, averages, and double-double production.
class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key, required this.username, this.games});

  final String username;

  /// The live games list from the app shell (the React app's `stats`
  /// prop). When provided it always wins over storage, so the summary
  /// updates the moment a game is logged. Standalone/tests may omit it and
  /// the screen falls back to reading storage itself.
  final List<GameStats>? games;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

/// One row of the summary table — mirrors `SummaryRow` in
/// `StatsSummaryPage.tsx`.
class _SummaryRow {
  const _SummaryRow({
    required this.label,
    required this.games,
    required this.teams,
    required this.record,
    required this.playerRecord,
    required this.missedRecord,
    required this.regularRecord,
    required this.playoffRecord,
    required this.gamesPlayed,
    required this.gamesAbsent,
    required this.points,
    required this.assists,
    required this.rebounds,
    required this.blocks,
    required this.steals,
    required this.minutes,
    required this.doubleDoubles,
    required this.tripleDoubles,
    required this.buzzerBeaters,
    required this.playoffBuzzerBeaters,
    required this.isCareer,
  });

  final String label;
  final List<GameStats> games;
  final String teams;
  final String record;
  final String playerRecord;
  final String missedRecord;
  final String regularRecord;
  final String playoffRecord;
  final int gamesPlayed;
  final int gamesAbsent;
  final double points;
  final double assists;
  final double rebounds;
  final double blocks;
  final double steals;
  final double minutes;
  final int doubleDoubles;
  final int tripleDoubles;
  final int buzzerBeaters;
  final int playoffBuzzerBeaters;
  final bool isCareer;
}

String _fmtAvg(double value) => value.toStringAsFixed(1);

String _fmtPct(double value) => '${(value * 100).toStringAsFixed(1)}%';

String _record(int wins, int total) => '$wins-${total - wins}';

/// Mirrors `buildSummaryRow` in StatsSummaryPage.tsx.
_SummaryRow _buildRow(
  String label,
  List<GameStats> games, {
  bool isCareer = false,
}) {
  final playedGames = games.where((g) => !g.isAbsent).toList();
  final missedGames = games.where((g) => g.isAbsent).toList();
  final regularGames = games
      .where((g) => g.gameType == GameType.regular)
      .toList();
  final playoffGames = games
      .where((g) => g.gameType == GameType.playoffs)
      .toList();
  final wins = games.where((g) => g.won).length;
  final playerWins = playedGames.where((g) => g.won).length;
  final missedWins = missedGames.where((g) => g.won).length;
  final regularWins = regularGames.where((g) => g.won).length;
  final playoffWins = playoffGames.where((g) => g.won).length;
  final teams = games.map((g) => g.team).toSet().join(', ');

  double avg(int Function(GameStats) pick) => playedGames.isEmpty
      ? 0
      : playedGames.map(pick).reduce((a, b) => a + b) / playedGames.length;

  return _SummaryRow(
    label: label,
    games: games,
    teams: teams.isEmpty ? '-' : teams,
    record: _record(wins, games.length),
    playerRecord: _record(playerWins, playedGames.length),
    missedRecord: _record(missedWins, missedGames.length),
    regularRecord: _record(regularWins, regularGames.length),
    playoffRecord: _record(playoffWins, playoffGames.length),
    gamesPlayed: playedGames.length,
    gamesAbsent: missedGames.length,
    points: avg((g) => g.points),
    assists: avg((g) => g.assists),
    rebounds: avg((g) => g.rebounds),
    blocks: avg((g) => g.blocks),
    steals: avg((g) => g.steals),
    minutes: avg((g) => g.minutes),
    doubleDoubles: playedGames.where((g) => g.isDoubleDouble).length,
    tripleDoubles: playedGames.where((g) => g.isTripleDouble).length,
    buzzerBeaters: games.where((g) => g.isBuzzerBeater).length,
    playoffBuzzerBeaters: playoffGames.where((g) => g.isBuzzerBeater).length,
    isCareer: isCareer,
  );
}

class _SummaryScreenState extends State<SummaryScreen> {
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
  void didUpdateWidget(SummaryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-sync whenever the shell pushes a new games list (e.g. after
    // logging a game) — the IndexedStack keeps this state object alive, so
    // prop changes arrive here rather than through initState.
    if (!identical(oldWidget.games, widget.games)) {
      setState(() => _games = widget.games ?? _games);
    }
  }

  Future<void> _refresh() => _loadGames();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Season Summary')),
      body: RefreshIndicator(onRefresh: _refresh, child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (_games.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          GlassCard(
            child: Column(
              children: [
                Text(
                  'No games logged yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Submit regular-season or playoff games from the tracker to '
                  'populate the season summary table.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Per-season rows (most recent first) + career row, mirroring
    // `summaryRows` in StatsSummaryPage.tsx.
    final seasons = organizeSeasonStats(_games);
    final seasonRows = seasons
        .map(
          (s) => _buildRow(s.seasonYear, [
            ...s.regularSeasonGames,
            ...s.playoffGames,
          ]),
        )
        .toList();
    final careerRow = _buildRow('Career Total', _games, isCareer: true);
    final summary = calculateStatsSummary(_games);
    final careerPpg = _fmtAvg(summary.averages.points);

    final bestScoring = seasonRows.isEmpty
        ? null
        : seasonRows.reduce(
            (best, row) => row.points > best.points ? row : best,
          );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 900 ? 64 : 16,
        vertical: 16,
      ),
      children: [
        // Hero — player record headline.
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Player analytics',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                'Season Summary',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              StatRow(
                label: 'Player Record',
                value: careerRow.playerRecord,
                emphasize: true,
              ),
              StatRow(
                label: 'Win rate when active',
                value: _fmtPct(summary.playerWinPercentage),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // KPI grid.
        _kpiGrid(careerRow, bestScoring, careerPpg),
        const SizedBox(height: 12),

        // Per-season + career comparison cards, mirroring the summary
        // table rows.
        for (final row in [...seasonRows, careerRow]) ...[
          _seasonCard(row),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _kpiGrid(
    _SummaryRow career,
    _SummaryRow? bestScoring,
    String careerPpg,
  ) {
    return GlassCard(
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          _tile('Logged Games', '${career.games.length}'),
          _tile('Games Played', '${career.gamesPlayed}'),
          _tile('Games Missed', '${career.gamesAbsent}'),
          _tile('Team Record', career.record),
          _tile('Career PPG', careerPpg),
          _tile(
            'Best PPG Season',
            bestScoring == null
                ? '-'
                : '${bestScoring.label} (${_fmtAvg(bestScoring.points)})',
          ),
          _tile(
            'Buzzer Beaters',
            '${career.buzzerBeaters} (${career.playoffBuzzerBeaters} PO)',
          ),
        ],
      ),
    );
  }

  Widget _tile(String label, String value) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _seasonCard(_SummaryRow row) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(row.label, style: Theme.of(context).textTheme.titleMedium),
              if (row.isCareer)
                Chip(
                  label: const Text('Career'),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          StatRow(label: 'Team', value: row.teams),
          StatRow(label: 'Player Record', value: row.playerRecord),
          StatRow(label: 'Missed Record', value: row.missedRecord),
          StatRow(label: 'Team Record', value: row.record),
          StatRow(label: 'Regular', value: row.regularRecord),
          StatRow(label: 'Playoffs', value: row.playoffRecord),
          StatRow(label: 'Logged', value: '${row.games.length}'),
          StatRow(label: 'Played', value: '${row.gamesPlayed}'),
          StatRow(label: 'Absent', value: '${row.gamesAbsent}'),
          StatRow(label: 'PPG', value: _fmtAvg(row.points)),
          StatRow(label: 'APG', value: _fmtAvg(row.assists)),
          StatRow(label: 'RPG', value: _fmtAvg(row.rebounds)),
          StatRow(label: 'BPG', value: _fmtAvg(row.blocks)),
          StatRow(label: 'SPG', value: _fmtAvg(row.steals)),
          StatRow(label: 'MPG', value: _fmtAvg(row.minutes)),
          StatRow(
            label: 'DD / TD',
            value: '${row.doubleDoubles} / ${row.tripleDoubles}',
          ),
          StatRow(
            label: 'Buzzer Beaters',
            value: '${row.buzzerBeaters} (${row.playoffBuzzerBeaters} PO)',
          ),
        ],
      ),
    );
  }
}
