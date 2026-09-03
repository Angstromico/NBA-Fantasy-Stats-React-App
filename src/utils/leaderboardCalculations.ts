import type { GameStats } from '../interfaces'
import { REGULAR_SEASON_GAME_COUNT } from '../data/nbaData'
import { LEADERBOARDS } from '../data/nbaLeaderboards'
import type { LeaderboardDef, LeaderboardEntry } from '../data/nbaLeaderboards'

// A season must clear the league rate qualifier (~70% of an 82-game season)
// before its per-game averages can be ranked against NBA seasons.
export const SEASON_AVG_MIN_GAMES = Math.ceil(REGULAR_SEASON_GAME_COUNT * 0.7)

type StatKey = 'points' | 'assists' | 'rebounds' | 'blocks' | 'steals'

const SINGLE_GAME_BOARDS: Partial<Record<string, StatKey>> = {
  'sg-points': 'points',
  'sg-assists': 'assists',
  'sg-rebounds': 'rebounds',
  'sg-blocks': 'blocks',
  'sg-steals': 'steals',
}

const SEASON_AVG_BOARDS: Partial<Record<string, StatKey>> = {
  'season-ppg': 'points',
  'season-rpg': 'rebounds',
  'season-apg': 'assists',
  'season-bpg': 'blocks',
  'season-spg': 'steals',
}

const STAT_ADJECTIVES: Record<StatKey, string> = {
  points: 'point',
  assists: 'assist',
  rebounds: 'rebound',
  blocks: 'block',
  steals: 'steal',
}

export interface LeaderboardRow {
  rank: number
  name: string
  value: number
  context: string
  isPlayer: boolean
}

/** One performance of the tracked player (a game, a season, a career total). */
export interface PlayerPerformance {
  value: number
  context: string
  sortKey: string
  /** 1-based position among the real all-time entries (ties broken by date). */
  rank: number
}

/** The player's best relevant mark, for "your best / not there yet" copy. */
export interface PlayerMarkInfo {
  value: number
  context: string
  sortKey: string
  games: number
  /** Whether the mark is eligible to be ranked (qualified season / complete season). */
  eligible: boolean
  /** All-time rank vs the real board, when meaningful. */
  rank: number | null
}

export interface LeaderboardView {
  board: LeaderboardDef
  rows: LeaderboardRow[]
  /** Player performances merged into the displayed board. */
  playerPerformances: PlayerPerformance[]
  /** Player performances that also make the board but were trimmed for tidiness. */
  extraPlayerCount: number
  mark: PlayerMarkInfo | null
}

export interface TopTwentyEntrance {
  boardId: string
  boardTitle: string
  /** Singular stat word, e.g. "point" or "rebound", for "a 63-point game". */
  adjective: string
  value: number
  context: string
  rank: number
}

const MAX_PLAYER_ROWS_PER_BOARD = 12

const formatGameDate = (date?: string): string => {
  if (!date) {
    return ''
  }
  const parsed = new Date(date)
  if (Number.isNaN(parsed.getTime())) {
    return date
  }
  return parsed.toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  })
}

const round2 = (value: number): number => Math.round(value * 100) / 100

/** True when entry `a` outranks `b` (higher value; equal values, earlier sortKey). */
const ranksAbove = (
  a: { value: number; sortKey?: string },
  b: { value: number; sortKey?: string },
): boolean => {
  if (a.value !== b.value) {
    return a.value > b.value
  }
  const aKey = a.sortKey || ''
  const bKey = b.sortKey || ''
  return aKey !== bKey ? aKey < bKey : false
}

const sortedEntries = (board: LeaderboardDef): LeaderboardEntry[] =>
  [...board.entries].sort((a, b) =>
    ranksAbove(a, b) ? -1 : ranksAbove(b, a) ? 1 : 0,
  )

/** The value a performance needs to at least reach to make the board. */
export const getBoardCutoffValue = (board: LeaderboardDef): number => {
  const cutoff = sortedEntries(board)[19]
  return cutoff ? cutoff.value : 0
}

/** 1-based rank `value`/`sortKey` holds among the real all-time entries. */
export const rankAgainstEntries = (
  board: LeaderboardDef,
  value: number,
  sortKey: string,
): number =>
  board.entries.filter((entry) => ranksAbove(entry, { value, sortKey })).length +
  1

// ---------------------------------------------------------------------------
// Candidate selectors — every qualifying performance of the tracked player.
// ---------------------------------------------------------------------------

const playedRegularGames = (games: GameStats[]): GameStats[] =>
  games.filter((game) => !game.isAbsent && game.gameType === 'regular')

type Candidate = PlayerMarkInfo

/** Candidates are ordered best-first by (value desc, sortKey asc). */
const sortCandidates = (candidates: Candidate[]): Candidate[] =>
  [...candidates].sort((a, b) =>
    ranksAbove(a, b) ? -1 : ranksAbove(b, a) ? 1 : 0,
  )

const singleGameCandidates = (
  games: GameStats[],
  stat: StatKey,
): Candidate[] => {
  const played = playedRegularGames(games)
  return played
    .filter((game) => game[stat] > 0)
    .map((game) => ({
      value: game[stat],
      context: `${formatGameDate(game.date)} · ${game.team} vs ${game.opponent}`,
      sortKey: game.date || '',
      games: 1,
      eligible: true,
      rank: 0,
    }))
}

const seasonAverageCandidates = (
  games: GameStats[],
  stat: StatKey,
): Candidate[] => {
  const buckets = new Map<string, GameStats[]>()
  playedRegularGames(games).forEach((game) => {
    const key = `${game.season || ''}::${game.team || ''}`
    const list = buckets.get(key) || []
    list.push(game)
    buckets.set(key, list)
  })

  const candidates: Candidate[] = []
  for (const [key, bucket] of buckets) {
    const season = key.split('::')[0]
    const total = bucket.reduce((sum, game) => sum + game[stat], 0)
    candidates.push({
      value: round2(total / bucket.length),
      context: `${season} season`,
      sortKey: season,
      games: bucket.length,
      eligible: bucket.length >= SEASON_AVG_MIN_GAMES,
      rank: 0,
    })
  }
  return candidates
}

const careerTripleDoubleCandidate = (games: GameStats[]): Candidate | null => {
  const played = playedRegularGames(games)
  const value = played.filter((game) => game.isTripleDouble).length
  if (played.length === 0) {
    return null
  }
  return {
    value,
    context: 'career',
    sortKey: 'career',
    games: played.length,
    eligible: true,
    rank: 0,
  }
}

const seasonTeamWinsCandidates = (games: GameStats[]): Candidate[] => {
  const buckets = new Map<string, GameStats[]>()
  games
    .filter((game) => game.gameType === 'regular')
    .forEach((game) => {
      const key = `${game.season || ''}::${game.team || ''}`
      const list = buckets.get(key) || []
      list.push(game)
      buckets.set(key, list)
    })

  const candidates: Candidate[] = []
  for (const [key, bucket] of buckets) {
    const season = key.split('::')[0]
    candidates.push({
      value: bucket.filter((game) => game.won).length,
      context: `${season} season`,
      sortKey: season,
      games: bucket.length,
      eligible: bucket.length >= REGULAR_SEASON_GAME_COUNT,
      rank: 0,
    })
  }
  return candidates
}

/** All candidate performances for a board, with ranks assigned. */
const boardCandidates = (
  board: LeaderboardDef,
  games: GameStats[],
): Candidate[] => {
  let candidates: Candidate[] = []
  const singleStat = SINGLE_GAME_BOARDS[board.id]
  if (singleStat) {
    candidates = singleGameCandidates(games, singleStat)
  } else if (SEASON_AVG_BOARDS[board.id]) {
    candidates = seasonAverageCandidates(games, SEASON_AVG_BOARDS[board.id] as StatKey)
  } else if (board.id === 'career-triple-doubles') {
    const candidate = careerTripleDoubleCandidate(games)
    candidates = candidate ? [candidate] : []
  } else if (board.id === 'team-season-wins') {
    candidates = seasonTeamWinsCandidates(games)
  }

  return sortCandidates(candidates).map((candidate) => ({
    ...candidate,
    rank: rankAgainstEntries(board, candidate.value, candidate.sortKey),
  }))
}

// ---------------------------------------------------------------------------
// View building — every player performance that cracks a top 20 is merged in.
// ---------------------------------------------------------------------------

const buildView = (
  board: LeaderboardDef,
  stats: GameStats[],
  playerName: string,
): LeaderboardView => {
  const cutoff = getBoardCutoffValue(board)
  const candidates = boardCandidates(board, stats)
  const onBoard = candidates.filter(
    (candidate) => candidate.eligible && candidate.value >= cutoff,
  )
  const extraPlayerCount = Math.max(0, onBoard.length - MAX_PLAYER_ROWS_PER_BOARD)
  const shownPerformances = onBoard.slice(0, MAX_PLAYER_ROWS_PER_BOARD)
  // Best mark worth reporting: the best eligible mark, or the best raw mark
  // when nothing is eligible yet (e.g. an in-progress season).
  const eligibleCandidates = candidates.filter((candidate) => candidate.eligible)
  const mark =
    (eligibleCandidates.length > 0 ? eligibleCandidates : candidates)[0] ||
    null

  const playerRows: { name: string; value: number; context: string; sortKey?: string; isPlayer?: boolean }[] =
    shownPerformances.map((performance) => ({
      name: playerName,
      value: performance.value,
      context: performance.context,
      sortKey: performance.sortKey,
      isPlayer: true,
    }))

  const allRows: {
    name: string
    value: number
    context: string
    sortKey?: string
    isPlayer?: boolean
  }[] = [...board.entries, ...playerRows]

  const rows: LeaderboardRow[] = allRows
    .sort((a, b) => (ranksAbove(a, b) ? -1 : ranksAbove(b, a) ? 1 : 0))
    .map((entry, index) => ({
      rank: index + 1,
      name: entry.name,
      value: entry.value,
      context: entry.context,
      isPlayer: Boolean(entry.isPlayer),
    }))

  return {
    board,
    rows,
    playerPerformances: shownPerformances.map((performance) => ({
      value: performance.value,
      context: performance.context,
      sortKey: performance.sortKey,
      rank: performance.rank ?? 0,
    })),
    extraPlayerCount,
    mark,
  }
}

export const buildLeaderboardViews = (
  stats: GameStats[],
  playerName: string,
): LeaderboardView[] =>
  LEADERBOARDS.map((board) => buildView(board, stats, playerName))

export const formatBoardValue = (
  value: number,
  board: LeaderboardDef,
): string => (board.format === 'dec' ? value.toFixed(2) : String(value))

// ---------------------------------------------------------------------------
// Congrats detection — call right after games are added to the tracker.
// ---------------------------------------------------------------------------

export const computeTopTwentyEntrances = (
  games: GameStats[],
): TopTwentyEntrance[] => {
  const entrances: TopTwentyEntrance[] = []

  games.forEach((game) => {
    if (game.isAbsent || game.gameType !== 'regular') {
      return
    }
    LEADERBOARDS.forEach((board) => {
      const stat = SINGLE_GAME_BOARDS[board.id]
      if (!stat) {
        return
      }
      const value = game[stat]
      if (value <= 0 || value < getBoardCutoffValue(board)) {
        return
      }
      entrances.push({
        boardId: board.id,
        boardTitle: board.title,
        adjective: STAT_ADJECTIVES[stat],
        value,
        context: `${formatGameDate(game.date)} · vs ${game.opponent}`,
        rank: rankAgainstEntries(board, value, game.date || ''),
      })
    })
  })

  return entrances.sort((a, b) => b.value - a.value)
}
