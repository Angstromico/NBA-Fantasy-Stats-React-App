import type { GameStats } from '../interfaces'

export type TopStatScope = 'all' | 'regular' | 'playoffs'

export interface TopGamePerformance {
  rank: number
  value: number
  statLabel: string
  game: GameStats
}

export interface StreakDetail {
  length: number
  current: number
  startDate?: string
  endDate?: string
  startOpponent?: string
  endOpponent?: string
  startSeason?: string
  endSeason?: string
  absenceReasons?: string[]
}

export interface ThresholdStreak {
  label: string
  threshold: number
  category: 'points' | 'assists' | 'rebounds' | 'steals' | 'blocks' | 'doubleDouble' | 'tripleDouble'
  longest: number
  current: number
  startDate?: string
  endDate?: string
  startOpponent?: string
  endOpponent?: string
  startSeason?: string
  endSeason?: string
}

export interface PlayerTopStatsResult {
  scope: TopStatScope
  totalGames: number
  playedGamesCount: number
  absentGamesCount: number

  // Peak single game bests
  topScoringGames: TopGamePerformance[]
  topAssistsGames: TopGamePerformance[]
  topReboundsGames: TopGamePerformance[]
  topStealsGames: TopGamePerformance[]
  topBlocksGames: TopGamePerformance[]
  topMinutesGames: TopGamePerformance[]
  buzzerBeaterGames: TopGamePerformance[]

  // Worst / tough outings
  worstScoringGames: TopGamePerformance[]

  // Team & Player Streaks
  teamWinStreak: StreakDetail
  playerWinStreak: StreakDetail
  teamLossStreak: StreakDetail
  playerLossStreak: StreakDetail
  absenceStreak: StreakDetail

  // Milestone Threshold Streaks
  scoringStreaks: ThresholdStreak[]
  playmakingStreaks: ThresholdStreak[]
  reboundingStreaks: ThresholdStreak[]
  defenseStreaks: ThresholdStreak[]
  allAroundStreaks: ThresholdStreak[]
}

export const sortGamesChronologically = (games: GameStats[]): GameStats[] => {
  return [...games].sort((a, b) => {
    const seasonCompare = (a.season || '').localeCompare(b.season || '')
    if (seasonCompare !== 0) return seasonCompare

    if (a.gameType !== b.gameType) {
      return a.gameType === 'regular' ? -1 : 1
    }

    if (a.gameNumber !== b.gameNumber) {
      return a.gameNumber - b.gameNumber
    }

    return (a.date || '').localeCompare(b.date || '')
  })
}

const filterGamesByScope = (games: GameStats[], scope: TopStatScope): GameStats[] => {
  if (scope === 'regular') {
    return games.filter((g) => g.gameType === 'regular')
  }
  if (scope === 'playoffs') {
    return games.filter((g) => g.gameType === 'playoffs')
  }
  return games
}

const getTopGames = (
  games: GameStats[],
  statKey: keyof Pick<GameStats, 'points' | 'assists' | 'rebounds' | 'steals' | 'blocks' | 'minutes'>,
  label: string,
  limit = 5,
  ascending = false,
): TopGamePerformance[] => {
  const eligible = games.filter((g) => !g.isAbsent)
  const sorted = [...eligible].sort((a, b) => {
    const diff = ascending ? a[statKey] - b[statKey] : b[statKey] - a[statKey]
    if (diff !== 0) return diff
    return ascending ? b.minutes - a.minutes : (b.date || '').localeCompare(a.date || '')
  })

  return sorted.slice(0, limit).map((game, index) => ({
    rank: index + 1,
    value: game[statKey],
    statLabel: label,
    game,
  }))
}

const calculateConsecutiveStreak = (
  games: GameStats[],
  predicate: (game: GameStats) => boolean,
): StreakDetail => {
  if (games.length === 0) {
    return { length: 0, current: 0 }
  }

  let longest = 0
  let longestStartGame: GameStats | undefined
  let longestEndGame: GameStats | undefined

  let tempLength = 0
  let tempStartGame: GameStats | undefined

  games.forEach((game) => {
    if (predicate(game)) {
      if (tempLength === 0) {
        tempStartGame = game
      }
      tempLength++
      if (tempLength > longest) {
        longest = tempLength
        longestStartGame = tempStartGame
        longestEndGame = game
      }
    } else {
      tempLength = 0
      tempStartGame = undefined
    }
  })

  let current = 0
  for (let i = games.length - 1; i >= 0; i--) {
    if (predicate(games[i])) {
      current++
    } else {
      break
    }
  }

  return {
    length: longest,
    current,
    startDate: longestStartGame?.date,
    endDate: longestEndGame?.date,
    startOpponent: longestStartGame?.opponent,
    endOpponent: longestEndGame?.opponent,
    startSeason: longestStartGame?.season,
    endSeason: longestEndGame?.season,
  }
}

const calculateThresholdStreak = (
  playedGames: GameStats[],
  label: string,
  threshold: number,
  category: ThresholdStreak['category'],
  predicate: (game: GameStats) => boolean,
): ThresholdStreak => {
  const streak = calculateConsecutiveStreak(playedGames, predicate)
  return {
    label,
    threshold,
    category,
    longest: streak.length,
    current: streak.current,
    startDate: streak.startDate,
    endDate: streak.endDate,
    startOpponent: streak.startOpponent,
    endOpponent: streak.endOpponent,
    startSeason: streak.startSeason,
    endSeason: streak.endSeason,
  }
}

export const calculatePlayerTopStats = (
  allGames: GameStats[],
  scope: TopStatScope = 'all',
): PlayerTopStatsResult => {
  const sorted = sortGamesChronologically(allGames)
  const scopedGames = filterGamesByScope(sorted, scope)
  const playedGames = scopedGames.filter((g) => !g.isAbsent)
  const absentGames = scopedGames.filter((g) => g.isAbsent)

  // Single-game peaks
  const topScoringGames = getTopGames(scopedGames, 'points', 'PTS')
  const topAssistsGames = getTopGames(scopedGames, 'assists', 'AST')
  const topReboundsGames = getTopGames(scopedGames, 'rebounds', 'REB')
  const topStealsGames = getTopGames(scopedGames, 'steals', 'STL')
  const topBlocksGames = getTopGames(scopedGames, 'blocks', 'BLK')
  const topMinutesGames = getTopGames(scopedGames, 'minutes', 'MIN')

  const buzzerBeaterGames = scopedGames
    .filter((g) => g.isBuzzerBeater)
    .sort((a, b) => b.points - a.points)
    .map((game, index) => ({
      rank: index + 1,
      value: game.points,
      statLabel: 'PTS',
      game,
    }))

  // Worst / tough outings (bottom scoring games with played time)
  const worstScoringGames = getTopGames(scopedGames, 'points', 'PTS', 5, true)

  // Team & Player Streaks
  const teamWinStreak = calculateConsecutiveStreak(scopedGames, (g) => g.won)
  const playerWinStreak = calculateConsecutiveStreak(playedGames, (g) => g.won)
  const teamLossStreak = calculateConsecutiveStreak(scopedGames, (g) => !g.won)
  const playerLossStreak = calculateConsecutiveStreak(playedGames, (g) => !g.won)

  // Longest absence streak
  const absenceStreakDetail = calculateConsecutiveStreak(scopedGames, (g) => g.isAbsent)
  const absenceReasons = Array.from(
    new Set(
      absentGames
        .filter((g) => g.absenceType !== 'none')
        .map((g) => g.absenceType.replace(/_/g, ' ')),
    ),
  )
  const absenceStreak: StreakDetail = {
    ...absenceStreakDetail,
    absenceReasons,
  }

  // Threshold streaks
  const scoringThresholds = [10, 20, 30, 40, 50]
  const scoringStreaks = scoringThresholds.map((threshold) =>
    calculateThresholdStreak(
      playedGames,
      `${threshold}+ PTS`,
      threshold,
      'points',
      (g) => g.points >= threshold,
    ),
  )

  const assistThresholds = [5, 10, 15]
  const playmakingStreaks = assistThresholds.map((threshold) =>
    calculateThresholdStreak(
      playedGames,
      `${threshold}+ AST`,
      threshold,
      'assists',
      (g) => g.assists >= threshold,
    ),
  )

  const reboundThresholds = [5, 10, 15]
  const reboundingStreaks = reboundThresholds.map((threshold) =>
    calculateThresholdStreak(
      playedGames,
      `${threshold}+ REB`,
      threshold,
      'rebounds',
      (g) => g.rebounds >= threshold,
    ),
  )

  const defenseStreaks = [
    calculateThresholdStreak(playedGames, '2+ Steals', 2, 'steals', (g) => g.steals >= 2),
    calculateThresholdStreak(playedGames, '2+ Blocks', 2, 'blocks', (g) => g.blocks >= 2),
  ]

  const allAroundStreaks = [
    calculateThresholdStreak(
      playedGames,
      'Double-Double',
      1,
      'doubleDouble',
      (g) => g.isDoubleDouble,
    ),
    calculateThresholdStreak(
      playedGames,
      'Triple-Double',
      1,
      'tripleDouble',
      (g) => g.isTripleDouble,
    ),
  ]

  return {
    scope,
    totalGames: scopedGames.length,
    playedGamesCount: playedGames.length,
    absentGamesCount: absentGames.length,
    topScoringGames,
    topAssistsGames,
    topReboundsGames,
    topStealsGames,
    topBlocksGames,
    topMinutesGames,
    buzzerBeaterGames,
    worstScoringGames,
    teamWinStreak,
    playerWinStreak,
    teamLossStreak,
    playerLossStreak,
    absenceStreak,
    scoringStreaks,
    playmakingStreaks,
    reboundingStreaks,
    defenseStreaks,
    allAroundStreaks,
  }
}
