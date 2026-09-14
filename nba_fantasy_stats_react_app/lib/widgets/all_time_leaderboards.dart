import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats_react_app/data/nba_leaderboards.dart';
import 'package:nba_fantasy_stats_react_app/models/game_stats.dart';
import 'package:nba_fantasy_stats_react_app/utils/leaderboard_calculations.dart';
import 'package:nba_fantasy_stats_react_app/widgets/glass_card.dart';

/// All-time leaderboards — Dart port of `AllTimeLeaderboards.tsx`. Merges the
/// tracked player's best games, seasons, and career marks into real NBA
/// top-20 boards, highlighting every performance that cracks a top 20.
class AllTimeLeaderboards extends StatelessWidget {
  const AllTimeLeaderboards({
    super.key,
    required this.stats,
    required this.playerName,
  });

  final List<GameStats> stats;
  final String playerName;

  static const _groupLabels = <LeaderboardGroup, String>{
    LeaderboardGroup.singleGame: 'Best Single Games',
    LeaderboardGroup.singleSeason: 'Best Single Seasons',
    LeaderboardGroup.career: 'Career Feats',
    LeaderboardGroup.team: 'Team Feats',
  };

  static const _groupOrder = [
    LeaderboardGroup.singleGame,
    LeaderboardGroup.singleSeason,
    LeaderboardGroup.career,
    LeaderboardGroup.team,
  ];

  String _boardCutoff(LeaderboardDef board) {
    final cutoff = getBoardCutoffValue(board);
    return cutoff > 0
        ? '${formatBoardValue(cutoff, board)} ${board.unit}'
        : '—';
  }

  @override
  Widget build(BuildContext context) {
    final views = buildLeaderboardViews(stats, playerName);
    final hasLoggedGames = stats.isNotEmpty;
    final boardsWithPlayer = views
        .where((view) => view.playerPerformances.isNotEmpty)
        .length;

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero.
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('All-time rankings', style: theme.textTheme.labelSmall),
                Text('Top 20 Leaderboards', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  "See how your player's best games, seasons, and career "
                  'marks stack up against the greatest in NBA history. Every '
                  "performance that cracks a top 20 — not just your single "
                  'best — is highlighted on its board.',
                  style: theme.textTheme.bodyMedium,
                ),
                if (hasLoggedGames && boardsWithPlayer > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    "🏆 You're currently on $boardsWithPlayer of "
                    '${leaderboards.length} boards.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        if (!hasLoggedGames)
          GlassCard(
            child: Column(
              children: [
                Text('No games logged yet', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Submit games from the tracker to start climbing the '
                  'all-time leaderboards.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          )
        else
          for (final group in _groupOrder) _groupSection(context, views, group),
      ],
    );
  }

  Widget _groupSection(
    BuildContext context,
    List<LeaderboardView> views,
    LeaderboardGroup group,
  ) {
    final groupViews = views
        .where((view) => view.board.group == group)
        .toList();
    if (groupViews.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_groupLabels[group]!, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final view in groupViews) ...[
          _LeaderboardBoard(view: view, cutoffText: _boardCutoff(view.board)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _LeaderboardBoard extends StatelessWidget {
  const _LeaderboardBoard({required this.view, required this.cutoffText});

  final LeaderboardView view;
  final String cutoffText;

  static const _playerQualifierCopy = <String, String>{
    'season-ppg': '58+ games played that season',
    'season-rpg': '58+ games played that season',
    'season-apg': '58+ games played that season',
    'season-bpg': '58+ games played that season',
    'season-spg': '58+ games played that season',
    'team-season-wins': 'a complete 82-game season',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final board = view.board;
    final accent = theme.colorScheme.primary;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(board.title, style: theme.textTheme.titleMedium),
              ),
              Text(
                'Top 20 needs $cutoffText',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
          Text(board.detail, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          ..._markStatus(theme, accent),
          const SizedBox(height: 8),
          Table(
            columnWidths: const {
              0: FixedColumnWidth(40),
              1: FlexColumnWidth(),
              2: IntrinsicColumnWidth(),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: theme.dividerColor)),
                ),
                children: [
                  _headCell(theme, 'Rank'),
                  _headCell(theme, 'Name'),
                  _headCell(theme, 'Mark', alignRight: true),
                ],
              ),
              for (final row in view.rows)
                TableRow(
                  decoration: BoxDecoration(
                    color: row.isPlayer ? accent.withValues(alpha: 0.10) : null,
                    border: Border(
                      bottom: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        '${row.rank}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  row.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: row.isPlayer ? accent : null,
                                  ),
                                ),
                              ),
                              if (row.isPlayer) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'You',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: accent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (row.context.isNotEmpty)
                            Text(row.context, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        '${formatBoardValue(row.value, board)} ${board.unit}',
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (board.note != null) ...[
            const SizedBox(height: 8),
            Text(board.note!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  List<Widget> _markStatus(ThemeData theme, Color accent) {
    final mark = view.mark;
    if (view.playerPerformances.isNotEmpty) {
      final extraCopy = view.extraPlayerCount > 0
          ? ' Another ${view.extraPlayerCount} of your performances also '
                'make the board.'
          : '';
      return [
        Text(
          "🏆 You're on this board — ${view.playerPerformances.length} "
          'top-20 performance${view.playerPerformances.length == 1 ? '' : 's'} '
          'highlighted below.$extraCopy',
          style: theme.textTheme.bodySmall?.copyWith(color: accent),
        ),
      ];
    }
    if (mark == null) {
      return const [];
    }
    if (!mark.eligible) {
      final qualifier = _playerQualifierCopy[view.board.id];
      return [
        Text.rich(
          TextSpan(
            style: theme.textTheme.bodySmall,
            children: [
              TextSpan(
                text:
                    'Your best: ${formatBoardValue(mark.value, view.board)} '
                    '${view.board.unit}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    ' over ${mark.games} games — ${qualifier ?? 'does not '
                            'qualify yet'} to rank.',
              ),
            ],
          ),
        ),
      ];
    }
    if (mark.rank != null) {
      return [
        Text.rich(
          TextSpan(
            style: theme.textTheme.bodySmall,
            children: [
              TextSpan(
                text:
                    'Your best: ${formatBoardValue(mark.value, view.board)} '
                    '${view.board.unit}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    ' ${mark.context} · ranks #${mark.rank} all-time — chase '
                    'the top 20.',
              ),
            ],
          ),
        ),
      ];
    }
    return const [];
  }

  Widget _headCell(ThemeData theme, String text, {bool alignRight = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          text,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}
