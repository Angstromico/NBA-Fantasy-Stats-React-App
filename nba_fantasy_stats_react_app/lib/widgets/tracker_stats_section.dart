import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats_react_app/models/career_highs.dart';
import 'package:nba_fantasy_stats_react_app/models/enums.dart';
import 'package:nba_fantasy_stats_react_app/models/game_stats.dart';
import 'package:nba_fantasy_stats_react_app/models/season_stats.dart';
import 'package:nba_fantasy_stats_react_app/models/stats_summary.dart';
import 'package:nba_fantasy_stats_react_app/theme/app_theme.dart';
import 'package:nba_fantasy_stats_react_app/utils/stats_calculations.dart';
import 'package:nba_fantasy_stats_react_app/widgets/glass_card.dart';
import 'package:nba_fantasy_stats_react_app/widgets/milestones_flip_card.dart';

/// The `StatsDisplay.tsx` port — everything rendered under the game form on
/// the tracker view: game list (last 5 / all, filterable by season), the
/// record flip card (current season ↔ career totals), streaks, averages
/// (current season / overall / regular / playoffs), season-by-season
/// cards, the milestones flip card, and career highs + totals.
class TrackerStatsSection extends StatefulWidget {
  const TrackerStatsSection({
    super.key,
    required this.stats,
    this.careerHighs,
    this.statsSummary,
    this.seasonStats = const [],
    this.currentSeason = '',
  });

  final List<GameStats> stats;
  final CareerHighs? careerHighs;
  final StatsSummary? statsSummary;
  final List<SeasonStats> seasonStats;
  final String currentSeason;

  @override
  State<TrackerStatsSection> createState() => _TrackerStatsSectionState();
}

class _TrackerStatsSectionState extends State<TrackerStatsSection> {
  bool _showAllGames = false;
  String _seasonFilter = 'all';

  String _seasonYearOf(GameStats game) =>
      game.season.isNotEmpty ? game.season : getSeasonYear(game.date);

  List<GameStats> get _filteredStats => _seasonFilter == 'all'
      ? widget.stats
      : widget.stats.where((g) => _seasonYearOf(g) == _seasonFilter).toList();

  List<GameStats> get _displayGames {
    final games = _filteredStats;
    if (_showAllGames || games.length <= 5) return games;
    return games.sublist(games.length - 5);
  }

  double _average(List<GameStats> games, int Function(GameStats) pick) {
    final played = games.where((g) => !g.isAbsent).toList();
    if (played.isEmpty) return 0;
    return played.map(pick).reduce((a, b) => a + b) / played.length;
  }

  Color _successColor(ThemeData theme) => theme.brightness == Brightness.dark
      ? AppTheme.successDark
      : AppTheme.successLight;

  String _streakLabel(int streak) {
    if (streak > 0) return 'W$streak';
    if (streak < 0) return 'L${-streak}';
    return 'None';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.stats.isEmpty) return const SizedBox.shrink();

    final trackedSeason = widget.currentSeason.isNotEmpty
        ? widget.currentSeason
        : (widget.seasonStats.isNotEmpty
              ? widget.seasonStats.first.seasonYear
              : _seasonYearOf(widget.stats.last));
    final currentSeasonGames = widget.stats
        .where((g) => _seasonYearOf(g) == trackedSeason)
        .toList();
    final currentSeasonPlayed = currentSeasonGames
        .where((g) => !g.isAbsent)
        .toList();
    final currentSeasonMissed = currentSeasonGames
        .where((g) => g.isAbsent)
        .toList();
    final currentSeasonPlayoffs = currentSeasonGames
        .where((g) => g.gameType == GameType.playoffs)
        .toList();
    final csWins = currentSeasonGames.where((g) => g.won).length;
    final csLosses = currentSeasonGames.length - csWins;
    final csPlayerWins = currentSeasonPlayed.where((g) => g.won).length;
    final csMissedWins = currentSeasonMissed.where((g) => g.won).length;
    final csPlayoffWins = currentSeasonPlayoffs.where((g) => g.won).length;

    String pct(double v) => '${(v * 100).toStringAsFixed(2)}%';
    final summary = widget.statsSummary;

    final totals = _Totals.of(widget.stats);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Game Statistics ────────────────────────────────────────────
        _SectionCard(
          title: 'Game Statistics',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.seasonStats.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    key: const ValueKey('season_filter'),
                    initialValue: _seasonFilter,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Season',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('All Seasons'),
                      ),
                      for (final season in widget.seasonStats)
                        DropdownMenuItem(
                          value: season.seasonYear,
                          child: Text('${season.seasonYear} Season'),
                        ),
                    ],
                    onChanged: (v) =>
                        setState(() => _seasonFilter = v ?? 'all'),
                  ),
                ),
              for (final game in _displayGames) _gameRecord(game, theme),
              const SizedBox(height: 12),
              Center(
                child: OutlinedButton(
                  onPressed: () =>
                      setState(() => _showAllGames = !_showAllGames),
                  child: Text(
                    _showAllGames ? 'Show Last 5 Games' : 'Show All Games',
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Overall Summary ────────────────────────────────────────────
        if (summary != null)
          _SectionCard(
            title: 'Overall Summary',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RecordFlipCard(
                  trackedSeason: trackedSeason,
                  season: _RecordFaceData(
                    playerGames:
                        '$csPlayerWins-${currentSeasonPlayed.length - csPlayerWins}',
                    missedGames:
                        '$csMissedWins-${currentSeasonMissed.length - csMissedWins}',
                    teamTotal: '$csWins-$csLosses',
                    playoffsTotal: currentSeasonPlayoffs.isEmpty
                        ? null
                        : '$csPlayoffWins-${currentSeasonPlayoffs.length - csPlayoffWins}',
                    playerWinPct: currentSeasonPlayed.isEmpty
                        ? '0.00%'
                        : pct(csPlayerWins / currentSeasonPlayed.length),
                    teamWinPct: currentSeasonGames.isEmpty
                        ? '0.00%'
                        : pct(csWins / currentSeasonGames.length),
                    missedWinPct: currentSeasonMissed.isEmpty
                        ? null
                        : pct(csMissedWins / currentSeasonMissed.length),
                    playoffWinPct: currentSeasonPlayoffs.isEmpty
                        ? null
                        : pct(csPlayoffWins / currentSeasonPlayoffs.length),
                  ),
                  career: _RecordFaceData(
                    playerGames:
                        '${summary.playerWins}-${summary.playerLosses}',
                    missedGames:
                        '${summary.missedWins}-${summary.missedLosses}',
                    teamTotal: '${summary.teamWins}-${summary.teamLosses}',
                    playoffsTotal:
                        '${summary.playoffWins}-${summary.playoffLosses}',
                    playerWinPct: pct(summary.playerWinPercentage),
                    teamWinPct: pct(summary.winPercentage),
                    missedWinPct: summary.gamesMissed > 0
                        ? pct(summary.missedWinPercentage)
                        : null,
                    playoffWinPct: summary.playoffWins > 0
                        ? pct(summary.playoffWinPercentage)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Streaks', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text('Current Streak: ${_streakLabel(summary.currentStreak)}'),
                Text('Longest Win Streak: ${summary.longestWinStreak}'),
                Text('Longest Loss Streak: ${summary.longestLossStreak}'),
                const SizedBox(height: 16),
                _averagesSection(theme, trackedSeason, currentSeasonGames),
              ],
            ),
          ),

        // ── Season by Season ───────────────────────────────────────────
        if (widget.seasonStats.isNotEmpty)
          _SectionCard(
            title: 'Season by Season Stats',
            child: Column(
              children: [
                for (final season in widget.seasonStats)
                  _seasonCard(season, theme),
              ],
            ),
          ),

        // ── Statistical Milestones ─────────────────────────────────────
        _SectionCard(
          title: 'Statistical Milestones',
          child: MilestonesFlipCard(
            currentMilestones: calculateStatisticalMilestones(
              currentSeasonGames,
            ),
            careerMilestones: calculateStatisticalMilestones(widget.stats),
          ),
        ),

        // ── Career Highs ───────────────────────────────────────────────
        if (widget.careerHighs != null)
          _SectionCard(
            title: 'Career Highs',
            child: Wrap(
              spacing: 28,
              runSpacing: 12,
              children: [
                _fact('Points', '${widget.careerHighs!.points}'),
                _fact('Assists', '${widget.careerHighs!.assists}'),
                _fact('Rebounds', '${widget.careerHighs!.rebounds}'),
                _fact('Blocks', '${widget.careerHighs!.blocks}'),
                _fact('Steals', '${widget.careerHighs!.steals}'),
                _fact('Minutes', '${widget.careerHighs!.minutes}'),
                _fact(
                  'Career Double-Doubles',
                  '${widget.careerHighs!.doubleDoubles}',
                ),
                _fact(
                  'Career Triple-Doubles',
                  '${widget.careerHighs!.tripleDoubles}',
                ),
              ],
            ),
          ),

        // ── Career Totals ──────────────────────────────────────────────
        _SectionCard(
          title: 'Career Totals',
          child: Wrap(
            spacing: 28,
            runSpacing: 12,
            children: [
              _fact('Total Points', '${totals.points}'),
              _fact('Total Assists', '${totals.assists}'),
              _fact('Total Rebounds', '${totals.rebounds}'),
              _fact('Total Blocks', '${totals.blocks}'),
              _fact('Total Steals', '${totals.steals}'),
              _fact('Total Minutes', '${totals.minutes}'),
              _fact('Total Games', '${widget.stats.length}'),
              _fact(
                'Games Played',
                '${widget.stats.where((g) => !g.isAbsent).length}',
              ),
              _fact(
                'Games Absent',
                '${widget.stats.where((g) => g.isAbsent).length}',
              ),
              _fact(
                'Total Buzzer Beaters',
                '${widget.stats.where((g) => g.isBuzzerBeater).length} 🔥',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fact(String label, String value) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _gameRecord(GameStats game, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: game.isAbsent
            ? theme.colorScheme.error.withValues(alpha: 0.06)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: game.isAbsent
              ? theme.colorScheme.error.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Game ${game.gameNumber} - '
            '${game.gameType == GameType.regular ? 'Regular Season' : 'Playoffs'}',
            style: theme.textTheme.titleSmall,
          ),
          Text('Date: ${game.date}'),
          Text('Team: ${game.team} vs ${game.opponent}'),
          if (game.isAbsent)
            Text(
              'Absent: ${game.absenceType.label}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            )
          else ...[
            Text('Minutes: ${game.minutes}'),
            Text('Points: ${game.points}'),
            Text('Assists: ${game.assists}'),
            Text('Rebounds: ${game.rebounds}'),
            Text('Blocks: ${game.blocks}'),
            Text('Steals: ${game.steals}'),
            Text('Double-Double: ${game.isDoubleDouble ? 'Yes' : 'No'}'),
            Text('Triple-Double: ${game.isTripleDouble ? 'Yes' : 'No'}'),
            Text('Buzzer Beater: ${game.isBuzzerBeater ? '🔥 Yes' : 'No'}'),
          ],
          Text(
            'Result: ${game.won ? 'Won' : 'Lost'}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: game.won ? _successColor(theme) : theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _averagesSection(
    ThemeData theme,
    String trackedSeason,
    List<GameStats> currentSeasonGames,
  ) {
    final summary = widget.statsSummary!;
    String f(double v) => v.toStringAsFixed(2);

    Widget block(
      String heading,
      List<(String, String)> rows, {
      String? note,
      String? empty,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: theme.textTheme.titleSmall),
          if (note != null)
            Text(
              note,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 2),
          if (empty != null)
            Text(empty, style: theme.textTheme.bodySmall)
          else
            for (final (label, value) in rows) Text('$label: $value'),
        ],
      );
    }

    final currentSeasonPlayed = currentSeasonGames
        .where((g) => !g.isAbsent)
        .toList();
    final currentRows = [
      ('Points', f(_average(currentSeasonGames, (g) => g.points))),
      ('Assists', f(_average(currentSeasonGames, (g) => g.assists))),
      ('Rebounds', f(_average(currentSeasonGames, (g) => g.rebounds))),
      ('Blocks', f(_average(currentSeasonGames, (g) => g.blocks))),
      ('Steals', f(_average(currentSeasonGames, (g) => g.steals))),
      ('Minutes', f(_average(currentSeasonGames, (g) => g.minutes))),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Averages', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (trackedSeason.isNotEmpty)
          block(
            'Current Season',
            currentRows,
            note:
                trackedSeason +
                (currentSeasonPlayed.isEmpty
                    ? ''
                    : ' · ${currentSeasonPlayed.length} game(s) played'),
            empty: currentSeasonPlayed.isEmpty
                ? (currentSeasonGames.isEmpty
                      ? 'No games logged yet this season'
                      : 'No games played yet this season')
                : null,
          ),
        const SizedBox(height: 12),
        block('Overall', [
          ('Points', f(summary.averages.points)),
          ('Assists', f(summary.averages.assists)),
          ('Rebounds', f(summary.averages.rebounds)),
          ('Blocks', f(summary.averages.blocks)),
          ('Steals', f(summary.averages.steals)),
          ('Minutes', f(summary.averages.minutes)),
        ]),
        const SizedBox(height: 12),
        block('Regular Season', [
          ('Points', f(summary.seasonAverages.points)),
          ('Assists', f(summary.seasonAverages.assists)),
          ('Rebounds', f(summary.seasonAverages.rebounds)),
          ('Blocks', f(summary.seasonAverages.blocks)),
          ('Steals', f(summary.seasonAverages.steals)),
          ('Minutes', f(summary.seasonAverages.minutes)),
        ]),
        if (summary.playoffAverages.points > 0) ...[
          const SizedBox(height: 12),
          block('Playoffs', [
            ('Points', f(summary.playoffAverages.points)),
            ('Assists', f(summary.playoffAverages.assists)),
            ('Rebounds', f(summary.playoffAverages.rebounds)),
            ('Blocks', f(summary.playoffAverages.blocks)),
            ('Steals', f(summary.playoffAverages.steals)),
            ('Minutes', f(summary.playoffAverages.minutes)),
          ]),
        ],
      ],
    );
  }

  Widget _seasonCard(SeasonStats season, ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${season.seasonYear} Season',
            style: theme.textTheme.titleSmall,
          ),
          Text('Team Games Logged: ${season.gamesPlayed}'),
          Text('Player Games Played: ${season.playerGamesPlayed}'),
          Text('Games Missed: ${season.gamesMissed}'),
          Text('Player Record: ${season.playerWins}-${season.playerLosses}'),
          Text(
            'Missed Games Record: ${season.missedWins}-${season.missedLosses}',
          ),
          Text('Team Total Record: ${season.teamWins}-${season.teamLosses}'),
          if (season.madePlayoffs) ...[
            const Text('Made Playoffs: Yes'),
            Text(
              'Playoff Record: ${season.playoffWins}-${season.playoffLosses}',
            ),
          ],
          Text('Double-Doubles: ${season.doubleDoubles}'),
          Text('Triple-Doubles: ${season.tripleDoubles}'),
        ],
      ),
    );
  }
}

/// Simple row totals across a game list (`totals` reduce in StatsDisplay).
class _Totals {
  const _Totals({
    required this.points,
    required this.assists,
    required this.rebounds,
    required this.blocks,
    required this.steals,
    required this.minutes,
  });

  factory _Totals.of(List<GameStats> games) => _Totals(
    points: games.fold(0, (a, g) => a + g.points),
    assists: games.fold(0, (a, g) => a + g.assists),
    rebounds: games.fold(0, (a, g) => a + g.rebounds),
    blocks: games.fold(0, (a, g) => a + g.blocks),
    steals: games.fold(0, (a, g) => a + g.steals),
    minutes: games.fold(0, (a, g) => a + g.minutes),
  );

  final int points;
  final int assists;
  final int rebounds;
  final int blocks;
  final int steals;
  final int minutes;
}

/// Glass card with a section heading.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// One face of the record flip card.
class _RecordFaceData {
  const _RecordFaceData({
    required this.playerGames,
    required this.missedGames,
    required this.teamTotal,
    required this.playoffsTotal,
    required this.playerWinPct,
    required this.teamWinPct,
    required this.missedWinPct,
    required this.playoffWinPct,
  });

  final String playerGames;
  final String missedGames;
  final String teamTotal;
  final String? playoffsTotal;
  final String playerWinPct;
  final String teamWinPct;
  final String? missedWinPct;
  final String? playoffWinPct;
}

/// The record flip card — current season ↔ career totals
/// (`.flip-card` in the summary grid of StatsDisplay.tsx).
class _RecordFlipCard extends StatefulWidget {
  const _RecordFlipCard({
    required this.trackedSeason,
    required this.season,
    required this.career,
  });

  final String trackedSeason;
  final _RecordFaceData season;
  final _RecordFaceData career;

  @override
  State<_RecordFlipCard> createState() => _RecordFlipCardState();
}

class _RecordFlipCardState extends State<_RecordFlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cue = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
    );

    Widget face(bool isBack) {
      final data = isBack ? widget.career : widget.season;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isBack ? 'Career Totals' : 'Current Season',
            style: theme.textTheme.titleSmall,
          ),
          if (!isBack)
            Text(
              widget.trackedSeason,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 4),
          Text('Player Games: ${data.playerGames}'),
          Text('Missed Games: ${data.missedGames}'),
          Text('Team Total: ${data.teamTotal}'),
          if (isBack || data.playoffsTotal != null)
            Text('Playoffs Team Total: ${data.playoffsTotal}'),
          Text('Player Win Percentage: ${data.playerWinPct}'),
          Text('Team Win Percentage: ${data.teamWinPct}'),
          if (data.missedWinPct != null)
            Text('Missed Games Win Percentage: ${data.missedWinPct}'),
          if (isBack || data.playoffWinPct != null)
            Text('Playoff Win Percentage: ${data.playoffWinPct}'),
          const SizedBox(height: 4),
          Text(
            isBack ? 'Tap for current season' : 'Tap for career totals',
            style: cue,
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () {
        if (_controller.value == 1) {
          _controller.reverse();
        } else {
          _controller.forward();
        }
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final angle = _controller.value * pi;
          final showBack = angle > pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: face(true),
                  )
                : face(false),
          );
        },
      ),
    );
  }
}
