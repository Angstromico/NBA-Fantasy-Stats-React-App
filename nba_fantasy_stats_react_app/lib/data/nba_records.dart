/// Real NBA records used by the app's "record chase" feature.
///
/// Dart port of `src/data/nbaRecords.ts`.
/// Values are verified against league history (as of 2025-26).
library;

/// Category of an NBA record.
enum NBARecordCategory {
  winStreak('win-streak'),
  scoringStreak('scoring-streak'),
  singleGame('single-game'),
  singleSeason('single-season');

  const NBARecordCategory(this.wireName);
  final String wireName;
}

/// Metric key identifying which player achievement a record compares to.
enum NBARecordMetric {
  winStreak,
  scoringStreak10,
  scoringStreak20,
  scoringStreak30,
  scoringStreak40,
  scoringStreak50,
  singleGamePoints,
  seasonPoints,
  seasonWins;

  static NBARecordMetric fromWire(String value) => values.firstWhere(
        (m) => m.name == value,
        orElse: () => NBARecordMetric.winStreak,
      );
}

/// One verifiable NBA record.
class NBARecord {
  const NBARecord({
    required this.id,
    required this.label,
    required this.holder,
    this.team,
    required this.season,
    required this.value,
    required this.unit,
    required this.category,
    required this.metric,
    required this.detail,
  });

  final String id;
  final String label;
  final String holder;
  final String? team;
  final String season;
  final num value;
  final String unit;
  final NBARecordCategory category;
  final NBARecordMetric metric;
  final String detail;
}

const List<NBARecord> nbaRecords = [
  // Winning streaks
  NBARecord(
    id: 'win-streak-33',
    label: 'Longest winning streak',
    holder: 'Los Angeles Lakers',
    season: '1971-72',
    value: 33,
    unit: 'games',
    category: NBARecordCategory.winStreak,
    metric: NBARecordMetric.winStreak,
    detail: '33 straight wins, the NBA record since 1972',
  ),
  NBARecord(
    id: 'win-streak-27',
    label: '2nd-longest winning streak',
    holder: 'Miami Heat',
    season: '2012-13',
    value: 27,
    unit: 'games',
    category: NBARecordCategory.winStreak,
    metric: NBARecordMetric.winStreak,
    detail: '27 straight wins in 2012-13',
  ),
  NBARecord(
    id: 'win-streak-24',
    label: 'Warriors winning streak',
    holder: 'Golden State Warriors',
    season: '2015-16',
    value: 24,
    unit: 'games',
    category: NBARecordCategory.winStreak,
    metric: NBARecordMetric.winStreak,
    detail: '24 straight wins to open 2015-16',
  ),
  // Consecutive scoring games
  NBARecord(
    id: 'scoring-streak-10',
    label: 'Most consecutive games with 10+ points',
    holder: 'LeBron James',
    team: 'Los Angeles Lakers',
    season: '2010-2025',
    value: 1297,
    unit: 'games',
    category: NBARecordCategory.scoringStreak,
    metric: NBARecordMetric.scoringStreak10,
    detail: '1,297 straight double-digit games, ended Dec 2025',
  ),
  NBARecord(
    id: 'scoring-streak-20',
    label: 'Most consecutive games with 20+ points',
    holder: 'Shai Gilgeous-Alexander',
    team: 'Oklahoma City Thunder',
    season: '2024-26',
    value: 127,
    unit: 'games',
    category: NBARecordCategory.scoringStreak,
    metric: NBARecordMetric.scoringStreak20,
    detail: 'Broke Wilt Chamberlain’s 126-game record (1961-63)',
  ),
  NBARecord(
    id: 'scoring-streak-30',
    label: 'Most consecutive games with 30+ points',
    holder: 'Wilt Chamberlain',
    team: 'Philadelphia Warriors',
    season: '1961-62',
    value: 65,
    unit: 'games',
    category: NBARecordCategory.scoringStreak,
    metric: NBARecordMetric.scoringStreak30,
    detail: '65 straight 30-point games',
  ),
  NBARecord(
    id: 'scoring-streak-40',
    label: 'Most consecutive games with 40+ points',
    holder: 'Wilt Chamberlain',
    team: 'Philadelphia Warriors',
    season: '1961-62',
    value: 14,
    unit: 'games',
    category: NBARecordCategory.scoringStreak,
    metric: NBARecordMetric.scoringStreak40,
    detail: '14 straight 40-point games',
  ),
  NBARecord(
    id: 'scoring-streak-50',
    label: 'Most consecutive games with 50+ points',
    holder: 'Wilt Chamberlain',
    team: 'Philadelphia Warriors',
    season: '1961-62',
    value: 7,
    unit: 'games',
    category: NBARecordCategory.scoringStreak,
    metric: NBARecordMetric.scoringStreak50,
    detail: '7 straight 50-point games',
  ),
  // Single game
  NBARecord(
    id: 'single-game-points',
    label: 'Most points in a single game',
    holder: 'Wilt Chamberlain',
    team: 'Philadelphia Warriors',
    season: '1961-62',
    value: 100,
    unit: 'points',
    category: NBARecordCategory.singleGame,
    metric: NBARecordMetric.singleGamePoints,
    detail: '100 points vs New York, Mar 2 1962',
  ),
  // Single season
  NBARecord(
    id: 'season-points',
    label: 'Most points in a single season',
    holder: 'Wilt Chamberlain',
    team: 'Philadelphia Warriors',
    season: '1961-62',
    value: 4029,
    unit: 'points',
    category: NBARecordCategory.singleSeason,
    metric: NBARecordMetric.seasonPoints,
    detail: '4,029 points at 50.4 ppg',
  ),
  NBARecord(
    id: 'season-wins',
    label: 'Most wins in a single season',
    holder: 'Golden State Warriors',
    season: '2015-16',
    value: 73,
    unit: 'wins',
    category: NBARecordCategory.singleSeason,
    metric: NBARecordMetric.seasonWins,
    detail: '73-9 record, the best regular season ever',
  ),
];
