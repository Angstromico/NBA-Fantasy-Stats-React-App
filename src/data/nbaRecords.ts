// Real NBA records used by the app's "record chase" feature.
// Values are verified against league history (as of 2025-26).

export type NBARecordCategory =
  | 'win-streak'
  | 'scoring-streak'
  | 'single-game'
  | 'single-season'

export type NBARecordMetric =
  | 'winStreak'
  | 'scoringStreak10'
  | 'scoringStreak20'
  | 'scoringStreak30'
  | 'scoringStreak40'
  | 'scoringStreak50'
  | 'singleGamePoints'
  | 'seasonPoints'
  | 'seasonWins'

export interface NBARecord {
  id: string
  label: string
  holder: string
  team?: string
  season: string
  value: number
  unit: string
  category: NBARecordCategory
  metric: NBARecordMetric
  detail: string
}

export const NBA_RECORDS: NBARecord[] = [
  // Winning streaks
  {
    id: 'win-streak-33',
    label: 'Longest winning streak',
    holder: 'Los Angeles Lakers',
    season: '1971-72',
    value: 33,
    unit: 'games',
    category: 'win-streak',
    metric: 'winStreak',
    detail: '33 straight wins, the NBA record since 1972',
  },
  {
    id: 'win-streak-27',
    label: '2nd-longest winning streak',
    holder: 'Miami Heat',
    season: '2012-13',
    value: 27,
    unit: 'games',
    category: 'win-streak',
    metric: 'winStreak',
    detail: '27 straight wins in 2012-13',
  },
  {
    id: 'win-streak-24',
    label: 'Warriors winning streak',
    holder: 'Golden State Warriors',
    season: '2015-16',
    value: 24,
    unit: 'games',
    category: 'win-streak',
    metric: 'winStreak',
    detail: '24 straight wins to open 2015-16',
  },
  // Consecutive scoring games
  {
    id: 'scoring-streak-10',
    label: 'Most consecutive games with 10+ points',
    holder: 'LeBron James',
    team: 'Los Angeles Lakers',
    season: '2010-2025',
    value: 1297,
    unit: 'games',
    category: 'scoring-streak',
    metric: 'scoringStreak10',
    detail: '1,297 straight double-digit games, ended Dec 2025',
  },
  {
    id: 'scoring-streak-20',
    label: 'Most consecutive games with 20+ points',
    holder: 'Shai Gilgeous-Alexander',
    team: 'Oklahoma City Thunder',
    season: '2024-26',
    value: 127,
    unit: 'games',
    category: 'scoring-streak',
    metric: 'scoringStreak20',
    detail: 'Broke Wilt Chamberlain\u2019s 126-game record (1961-63)',
  },
  {
    id: 'scoring-streak-30',
    label: 'Most consecutive games with 30+ points',
    holder: 'Wilt Chamberlain',
    team: 'Philadelphia Warriors',
    season: '1961-62',
    value: 65,
    unit: 'games',
    category: 'scoring-streak',
    metric: 'scoringStreak30',
    detail: '65 straight 30-point games',
  },
  {
    id: 'scoring-streak-40',
    label: 'Most consecutive games with 40+ points',
    holder: 'Wilt Chamberlain',
    team: 'Philadelphia Warriors',
    season: '1961-62',
    value: 14,
    unit: 'games',
    category: 'scoring-streak',
    metric: 'scoringStreak40',
    detail: '14 straight 40-point games',
  },
  {
    id: 'scoring-streak-50',
    label: 'Most consecutive games with 50+ points',
    holder: 'Wilt Chamberlain',
    team: 'Philadelphia Warriors',
    season: '1961-62',
    value: 7,
    unit: 'games',
    category: 'scoring-streak',
    metric: 'scoringStreak50',
    detail: '7 straight 50-point games',
  },
  // Single game
  {
    id: 'single-game-points',
    label: 'Most points in a single game',
    holder: 'Wilt Chamberlain',
    team: 'Philadelphia Warriors',
    season: '1961-62',
    value: 100,
    unit: 'points',
    category: 'single-game',
    metric: 'singleGamePoints',
    detail: '100 points vs New York, Mar 2 1962',
  },
  // Single season
  {
    id: 'season-points',
    label: 'Most points in a single season',
    holder: 'Wilt Chamberlain',
    team: 'Philadelphia Warriors',
    season: '1961-62',
    value: 4029,
    unit: 'points',
    category: 'single-season',
    metric: 'seasonPoints',
    detail: '4,029 points at 50.4 ppg',
  },
  {
    id: 'season-wins',
    label: 'Most wins in a single season',
    holder: 'Golden State Warriors',
    season: '2015-16',
    value: 73,
    unit: 'wins',
    category: 'single-season',
    metric: 'seasonWins',
    detail: '73-9 record, the best regular season ever',
  },
]