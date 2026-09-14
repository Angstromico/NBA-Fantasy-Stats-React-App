import 'package:nba_fantasy_stats_react_app/data/nba_data.dart';
import 'package:nba_fantasy_stats_react_app/data/nba_leaderboards.dart';
import 'package:nba_fantasy_stats_react_app/models/enums.dart';
import 'package:nba_fantasy_stats_react_app/models/game_stats.dart';

/// Dart port of `src/utils/leaderboardCalculations.ts` — ranks the tracked
/// player's performances against real NBA top-20 leaderboards.

/// League rate qualifier for season-average boards — a season must clear
/// ~70% of an 82-game season before its per-game averages can be ranked
/// against NBA seasons. Mirrors `SEASON_AVG_MIN_GAMES` in
/// leaderboardCalculations.ts.
int get seasonAvgMinGames => (regularSeasonGameCount * 0.7).ceil();

/// One of `'points' | 'assists' | 'rebounds' | 'blocks' | 'steals'`.
typedef StatKey = String;

const Map<String, StatKey> _singleGameBoards = {
  'sg-points': 'points',
  'sg-assists': 'assists',
  'sg-rebounds': 'rebounds',
  'sg-blocks': 'blocks',
  'sg-steals': 'steals',
};

const Map<String, StatKey> _seasonAvgBoards = {
  'season-ppg': 'points',
  'season-rpg': 'rebounds',
  'season-apg': 'assists',
  'season-bpg': 'blocks',
  'season-spg': 'steals',
};

const Map<StatKey, String> _statAdjectives = {
  'points': 'point',
  'assists': 'assist',
  'rebounds': 'rebound',
  'blocks': 'block',
  'steals': 'steal',
};

int _statValue(GameStats game, StatKey stat) => switch (stat) {
  'points' => game.points,
  'assists' => game.assists,
  'rebounds' => game.rebounds,
  'blocks' => game.blocks,
  'steals' => game.steals,
  _ => throw ArgumentError('Unknown stat: $stat'),
};

class LeaderboardRow {
  const LeaderboardRow({
    required this.rank,
    required this.name,
    required this.value,
    required this.context,
    required this.isPlayer,
  });

  final int rank;
  final String name;
  final num value;
  final String context;
  final bool isPlayer;
}

/// One performance of the tracked player (a game, a season, a career total).
class PlayerPerformance {
  const PlayerPerformance({
    required this.value,
    required this.context,
    required this.sortKey,
    required this.rank,
  });

  final num value;
  final String context;
  final String sortKey;

  /// 1-based position among the real all-time entries (ties broken by date).
  final int rank;
}

/// The player's best relevant mark, for "your best / not there yet" copy.
class PlayerMarkInfo {
  const PlayerMarkInfo({
    required this.value,
    required this.context,
    required this.sortKey,
    required this.games,
    required this.eligible,
    required this.rank,
  });

  final num value;
  final String context;
  final String sortKey;
  final int games;

  /// Whether the mark is eligible to be ranked (qualified season / complete
  /// season).
  final bool eligible;

  /// All-time rank vs the real board, when meaningful.
  final int? rank;
}

class LeaderboardView {
  const LeaderboardView({
    required this.board,
    required this.rows,
    required this.playerPerformances,
    required this.extraPlayerCount,
    required this.mark,
  });

  final LeaderboardDef board;
  final List<LeaderboardRow> rows;

  /// Player performances merged into the displayed board.
  final List<PlayerPerformance> playerPerformances;

  /// Player performances that also make the board but were trimmed for
  /// tidiness.
  final int extraPlayerCount;
  final PlayerMarkInfo? mark;
}

class TopTwentyEntrance {
  const TopTwentyEntrance({
    required this.boardId,
    required this.boardTitle,
    required this.adjective,
    required this.value,
    required this.context,
    required this.rank,
  });

  final String boardId;
  final String boardTitle;

  /// Singular stat word, e.g. "point" or "rebound", for "a 63-point game".
  final String adjective;
  final num value;
  final String context;
  final int rank;
}

const int _maxPlayerRowsPerBoard = 12;

String _formatGameDate(String? date) {
  if (date == null || date.isEmpty) return '';
  final parsed = DateTime.tryParse(date);
  if (parsed == null) return date;
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
}

num _round2(num value) => (value * 100).round() / 100;

// ---------------------------------------------------------------------------
// Ranking helpers
// ---------------------------------------------------------------------------

/// Minimal ranking key shared by real entries, player candidates, and merged
/// rows (mirrors the `{ value, sortKey? }` structural type in the TS source).
typedef _RankedKey = ({num value, String sortKey});

/// True when entry [a] outranks [b] (higher value; equal values, earlier
/// sortKey).
bool _ranksAbove(_RankedKey a, _RankedKey b) {
  if (a.value != b.value) {
    return a.value > b.value;
  }
  return a.sortKey != b.sortKey ? a.sortKey.compareTo(b.sortKey) < 0 : false;
}

/// Stable best-first sort (value desc, sortKey asc, full ties keep insertion
/// order) — replicates the stable `Array.prototype.sort` semantics used by
/// the TS source.
List<T> _rankSort<T>(Iterable<T> items, _RankedKey Function(T) keyOf) {
  final indexed = [for (final (index, item) in items.indexed) (index, item)];
  indexed.sort((a, b) {
    if (_ranksAbove(keyOf(a.$2), keyOf(b.$2))) return -1;
    if (_ranksAbove(keyOf(b.$2), keyOf(a.$2))) return 1;
    return a.$1.compareTo(b.$1);
  });
  return [for (final entry in indexed) entry.$2];
}

_RankedKey _entryKey(LeaderboardEntry entry) =>
    (value: entry.value, sortKey: entry.sortKey);

List<LeaderboardEntry> _sortedEntries(LeaderboardDef board) =>
    _rankSort(board.entries, _entryKey);

/// The value a performance needs to at least reach to make the board.
num getBoardCutoffValue(LeaderboardDef board) =>
    _sortedEntries(board).elementAtOrNull(19)?.value ?? 0;

/// 1-based rank `value`/`sortKey` holds among the real all-time entries.
int rankAgainstEntries(LeaderboardDef board, num value, String sortKey) =>
    board.entries
        .where(
          (entry) =>
              _ranksAbove(_entryKey(entry), (value: value, sortKey: sortKey)),
        )
        .length +
    1;

// ---------------------------------------------------------------------------
// Candidate selectors — every qualifying performance of the tracked player.
// ---------------------------------------------------------------------------

typedef _Candidate = ({
  num value,
  String context,
  String sortKey,
  int games,
  bool eligible,
});

List<GameStats> _playedRegularGames(List<GameStats> games) => games
    .where((game) => !game.isAbsent && game.gameType == GameType.regular)
    .toList();

List<_Candidate> _singleGameCandidates(
  List<GameStats> games,
  StatKey stat,
) => _playedRegularGames(games)
    .where((game) => _statValue(game, stat) > 0)
    .map(
      (game) => (
        value: _statValue(game, stat),
        context:
            '${_formatGameDate(game.date)} · ${game.team} vs ${game.opponent}',
        sortKey: game.date.isNotEmpty ? game.date : '',
        games: 1,
        eligible: true,
      ),
    )
    .toList();

List<_Candidate> _seasonAverageCandidates(List<GameStats> games, StatKey stat) {
  final buckets = <String, List<GameStats>>{};
  for (final game in _playedRegularGames(games)) {
    final key = '${game.season}::${game.team}';
    buckets.putIfAbsent(key, () => []).add(game);
  }

  final candidates = <_Candidate>[];
  for (final bucket in buckets.values) {
    final season = bucket.first.season;
    final total = bucket.fold<int>(
      0,
      (sum, game) => sum + _statValue(game, stat),
    );
    candidates.add((
      value: _round2(total / bucket.length),
      context: '$season season',
      sortKey: season,
      games: bucket.length,
      eligible: bucket.length >= seasonAvgMinGames,
    ));
  }
  return candidates;
}

_Candidate? _careerTripleDoubleCandidate(List<GameStats> games) {
  final played = _playedRegularGames(games);
  if (played.isEmpty) return null;
  final value = played.where((game) => game.isTripleDouble).length;
  return (
    value: value,
    context: 'career',
    sortKey: 'career',
    games: played.length,
    eligible: true,
  );
}

List<_Candidate> _seasonTeamWinsCandidates(List<GameStats> games) {
  final buckets = <String, List<GameStats>>{};
  for (final game in games.where((game) => game.gameType == GameType.regular)) {
    final key = '${game.season}::${game.team}';
    buckets.putIfAbsent(key, () => []).add(game);
  }

  final candidates = <_Candidate>[];
  for (final bucket in buckets.values) {
    final season = bucket.first.season;
    candidates.add((
      value: bucket.where((game) => game.won).length,
      context: '$season season',
      sortKey: season,
      games: bucket.length,
      eligible: bucket.length >= regularSeasonGameCount,
    ));
  }
  return candidates;
}

/// All candidate performances for a board, ordered best-first.
List<_Candidate> _boardCandidates(LeaderboardDef board, List<GameStats> games) {
  var candidates = const <_Candidate>[];
  final singleStat = _singleGameBoards[board.id];
  if (singleStat != null) {
    candidates = _singleGameCandidates(games, singleStat);
  } else if (_seasonAvgBoards.containsKey(board.id)) {
    candidates = _seasonAverageCandidates(games, _seasonAvgBoards[board.id]!);
  } else if (board.id == 'career-triple-doubles') {
    final candidate = _careerTripleDoubleCandidate(games);
    candidates = candidate == null ? const <_Candidate>[] : [candidate];
  } else if (board.id == 'team-season-wins') {
    candidates = _seasonTeamWinsCandidates(games);
  }

  return _rankSort(
    candidates,
    (candidate) => (value: candidate.value, sortKey: candidate.sortKey),
  );
}

// ---------------------------------------------------------------------------
// View building — every player performance that cracks a top 20 is merged in.
// ---------------------------------------------------------------------------

LeaderboardView _buildView(
  LeaderboardDef board,
  List<GameStats> stats,
  String playerName,
) {
  final cutoff = getBoardCutoffValue(board);
  final candidates = _boardCandidates(board, stats);
  final onBoard = candidates
      .where((candidate) => candidate.eligible && candidate.value >= cutoff)
      .toList();
  final extraPlayerCount = onBoard.length > _maxPlayerRowsPerBoard
      ? onBoard.length - _maxPlayerRowsPerBoard
      : 0;
  final shownPerformances = onBoard.take(_maxPlayerRowsPerBoard).toList();

  // Best mark worth reporting: the best eligible mark, or the best raw mark
  // when nothing is eligible yet (e.g. an in-progress season).
  final eligibleCandidates = candidates
      .where((candidate) => candidate.eligible)
      .toList();
  final bestPool = eligibleCandidates.isNotEmpty
      ? eligibleCandidates
      : candidates;
  final best = bestPool.isEmpty ? null : bestPool.first;
  final mark = best == null
      ? null
      : PlayerMarkInfo(
          value: best.value,
          context: best.context,
          sortKey: best.sortKey,
          games: best.games,
          eligible: best.eligible,
          rank: best.eligible
              ? rankAgainstEntries(board, best.value, best.sortKey)
              : null,
        );

  final allRows = _rankSort([
    ...board.entries.map(
      (entry) => (
        name: entry.name,
        value: entry.value,
        context: entry.context,
        sortKey: entry.sortKey,
        isPlayer: false,
      ),
    ),
    ...shownPerformances.map(
      (performance) => (
        name: playerName,
        value: performance.value,
        context: performance.context,
        sortKey: performance.sortKey,
        isPlayer: true,
      ),
    ),
  ], (row) => (value: row.value, sortKey: row.sortKey));

  final rows = [
    for (final (index, row) in allRows.indexed)
      LeaderboardRow(
        rank: index + 1,
        name: row.name,
        value: row.value,
        context: row.context,
        isPlayer: row.isPlayer,
      ),
  ];

  return LeaderboardView(
    board: board,
    rows: rows,
    playerPerformances: [
      for (final performance in shownPerformances)
        PlayerPerformance(
          value: performance.value,
          context: performance.context,
          sortKey: performance.sortKey,
          rank: rankAgainstEntries(
            board,
            performance.value,
            performance.sortKey,
          ),
        ),
    ],
    extraPlayerCount: extraPlayerCount,
    mark: mark,
  );
}

List<LeaderboardView> buildLeaderboardViews(
  List<GameStats> stats,
  String playerName,
) => leaderboards.map((board) => _buildView(board, stats, playerName)).toList();

String formatBoardValue(num value, LeaderboardDef board) =>
    board.format == 'dec' ? value.toStringAsFixed(2) : '$value';

// ---------------------------------------------------------------------------
// Congrats detection — call right after games are added to the tracker.
// ---------------------------------------------------------------------------

List<TopTwentyEntrance> computeTopTwentyEntrances(List<GameStats> games) {
  final entrances = <TopTwentyEntrance>[];

  for (final game in games) {
    if (game.isAbsent || game.gameType != GameType.regular) {
      continue;
    }
    for (final board in leaderboards) {
      final stat = _singleGameBoards[board.id];
      if (stat == null) {
        continue;
      }
      final value = _statValue(game, stat);
      if (value <= 0 || value < getBoardCutoffValue(board)) {
        continue;
      }
      entrances.add(
        TopTwentyEntrance(
          boardId: board.id,
          boardTitle: board.title,
          adjective: _statAdjectives[stat] ?? stat,
          value: value,
          context: '${_formatGameDate(game.date)} · vs ${game.opponent}',
          rank: rankAgainstEntries(board, value, game.date),
        ),
      );
    }
  }

  // Sort best-first by value only (stable for ties), matching the TS source.
  final indexed = [for (final (i, e) in entrances.indexed) (i, e)];
  indexed.sort((a, b) {
    final byValue = b.$2.value.compareTo(a.$2.value);
    return byValue != 0 ? byValue : a.$1.compareTo(b.$1);
  });
  return [for (final entry in indexed) entry.$2];
}
