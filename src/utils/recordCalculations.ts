import type { GameStats } from '../interfaces'
import { NBA_RECORDS } from '../data/nbaRecords'
import type { NBARecord, NBARecordMetric } from '../data/nbaRecords'

export interface ScoringStreakInfo {
  threshold: number
  current: number
  longest: number
  longestStart?: string
  longestEnd?: string
}

export interface RecordAchievements {
  currentWinStreak: number
  longestWinStreak: number
  longestWinStart?: string
  longestWinEnd?: string
  currentLossStreak: number
  longestLossStreak: number
  longestLossStart?: string
  longestLossEnd?: string
  scoringStreaks: ScoringStreakInfo[]
  singleGamePoints: number
  singleGamePointsSeason?: string
  seasonPoints: number
  seasonPointsSeason?: string
  seasonWins: number
  seasonWinsSeason?: string
}

export interface RecordComparison {
  record: NBARecord
  playerValue: number
  currentValue?: number
  broken: boolean
  remaining: number
}

const SCORING_THRESHOLDS = [10, 20, 30, 40, 50]

const sortGamesChronologically = (games: GameStats[]): GameStats[] =>
  [...games].sort((a, b) => {
    const dateCompare = (a.date || '').localeCompare(b.date || '')
    return dateCompare !== 0 ? dateCompare : a.gameNumber - b.gameNumber
  })

// Consecutive games with at least `threshold` points, based on games played
// (a missed/absent game does not break a scoring streak).
export const calculateScoringStreak = (
  games: GameStats[],
  threshold: number,
): ScoringStreakInfo => {
  const playedGames = sortGamesChronologically(games).filter(
    (game) => !game.isAbsent,
  )

  let current = 0
  let longest = 0
  let temp = 0
  let tempStart: string | undefined
  let longestStart: string | undefined
  let longestEnd: string | undefined

  playedGames.forEach((game) => {
    if (game.points >= threshold) {
      if (temp === 0) {
        tempStart = game.date
      }
      temp++
      if (temp > longest) {
        longest = temp
        longestStart = tempStart
        longestEnd = game.date
      }
    } else {
      temp = 0
      tempStart = undefined
    }
  })

  for (let i = playedGames.length - 1; i >= 0; i--) {
    if (playedGames[i].points >= threshold) {
      current++
    } else {
      break
    }
  }

  return {
    threshold,
    current,
    longest,
    longestStart,
    longestEnd,
  }
}

export const calculateWinLossStreaks = (
  games: GameStats[],
): {
  currentWinStreak: number
  longestWinStreak: number
  longestWinStart?: string
  longestWinEnd?: string
  currentLossStreak: number
  longestLossStreak: number
  longestLossStart?: string
  longestLossEnd?: string
} => {
  const ordered = sortGamesChronologically(games)

  let longestWinStreak = 0
  let longestWinStart: string | undefined
  let longestWinEnd: string | undefined
  let longestLossStreak = 0
  let longestLossStart: string | undefined
  let longestLossEnd: string | undefined
  let tempWin = 0
  let tempWinStart: string | undefined
  let tempLoss = 0
  let tempLossStart: string | undefined

  ordered.forEach((game) => {
    if (game.won) {
      if (tempWin === 0) {
        tempWinStart = game.date
      }
      tempWin++
      tempLoss = 0
      if (tempWin > longestWinStreak) {
        longestWinStreak = tempWin
        longestWinStart = tempWinStart
        longestWinEnd = game.date
      }
    } else {
      if (tempLoss === 0) {
        tempLossStart = game.date
      }
      tempLoss++
      tempWin = 0
      if (tempLoss > longestLossStreak) {
        longestLossStreak = tempLoss
        longestLossStart = tempLossStart
        longestLossEnd = game.date
      }
    }
  })

  let currentWinStreak = 0
  let currentLossStreak = 0

  for (let i = ordered.length - 1; i >= 0; i--) {
    if (ordered[i].won) {
      currentWinStreak++
    } else {
      break
    }
  }

  for (let i = ordered.length - 1; i >= 0; i--) {
    if (!ordered[i].won) {
      currentLossStreak++
    } else {
      break
    }
  }

  return {
    currentWinStreak,
    longestWinStreak,
    longestWinStart,
    longestWinEnd,
    currentLossStreak,
    longestLossStreak,
    longestLossStart,
    longestLossEnd,
  }
}

export const getRecordAchievements = (
  games: GameStats[],
): RecordAchievements => {
  const playedGames = games.filter((game) => !game.isAbsent)
  const winLoss = calculateWinLossStreaks(games)

  const seasonTotals = new Map<string, { points: number; wins: number }>()
  games.forEach((game) => {
    const season = game.season || 'unknown'
    const entry = seasonTotals.get(season) || { points: 0, wins: 0 }
    if (!game.isAbsent) {
      entry.points += game.points
    }
    if (game.won) {
      entry.wins++
    }
    seasonTotals.set(season, entry)
  })

  let singleGamePoints = 0
  let singleGamePointsSeason: string | undefined
  let seasonPoints = 0
  let seasonPointsSeason: string | undefined
  let seasonWins = 0
  let seasonWinsSeason: string | undefined

  playedGames.forEach((game) => {
    if (game.points > singleGamePoints) {
      singleGamePoints = game.points
      singleGamePointsSeason = game.season
    }
  })

  seasonTotals.forEach((totals, season) => {
    if (totals.points > seasonPoints) {
      seasonPoints = totals.points
      seasonPointsSeason = season
    }
    if (totals.wins > seasonWins) {
      seasonWins = totals.wins
      seasonWinsSeason = season
    }
  })

  return {
    currentWinStreak: winLoss.currentWinStreak,
    longestWinStreak: winLoss.longestWinStreak,
    longestWinStart: winLoss.longestWinStart,
    longestWinEnd: winLoss.longestWinEnd,
    currentLossStreak: winLoss.currentLossStreak,
    longestLossStreak: winLoss.longestLossStreak,
    longestLossStart: winLoss.longestLossStart,
    longestLossEnd: winLoss.longestLossEnd,
    scoringStreaks: SCORING_THRESHOLDS.map((threshold) =>
      calculateScoringStreak(games, threshold),
    ),
    singleGamePoints,
    singleGamePointsSeason,
    seasonPoints,
    seasonPointsSeason,
    seasonWins,
    seasonWinsSeason,
  }
}

const getScoringStreak = (
  achievements: RecordAchievements,
  threshold: number,
): ScoringStreakInfo =>
  achievements.scoringStreaks.find(
    (streak) => streak.threshold === threshold,
  ) || { threshold, current: 0, longest: 0 }

export const getAchievementValue = (
  achievements: RecordAchievements,
  metric: NBARecordMetric,
): number => {
  switch (metric) {
    case 'winStreak':
      return achievements.longestWinStreak
    case 'scoringStreak10':
      return getScoringStreak(achievements, 10).longest
    case 'scoringStreak20':
      return getScoringStreak(achievements, 20).longest
    case 'scoringStreak30':
      return getScoringStreak(achievements, 30).longest
    case 'scoringStreak40':
      return getScoringStreak(achievements, 40).longest
    case 'scoringStreak50':
      return getScoringStreak(achievements, 50).longest
    case 'singleGamePoints':
      return achievements.singleGamePoints
    case 'seasonPoints':
      return achievements.seasonPoints
    case 'seasonWins':
      return achievements.seasonWins
  }
}

export const getCurrentValue = (
  achievements: RecordAchievements,
  metric: NBARecordMetric,
): number | undefined => {
  switch (metric) {
    case 'winStreak':
      return achievements.currentWinStreak
    case 'scoringStreak10':
      return getScoringStreak(achievements, 10).current
    case 'scoringStreak20':
      return getScoringStreak(achievements, 20).current
    case 'scoringStreak30':
      return getScoringStreak(achievements, 30).current
    case 'scoringStreak40':
      return getScoringStreak(achievements, 40).current
    case 'scoringStreak50':
      return getScoringStreak(achievements, 50).current
    default:
      return undefined
  }
}

export const compareToNBARecords = (
  achievements: RecordAchievements,
): RecordComparison[] =>
  NBA_RECORDS.map((record) => {
    const playerValue = getAchievementValue(achievements, record.metric)
    const currentValue = getCurrentValue(achievements, record.metric)
    return {
      record,
      playerValue,
      currentValue,
      broken: playerValue >= record.value,
      remaining: Math.max(0, record.value - playerValue),
    }
  })

export const getBrokenRecords = (
  games: GameStats[],
): RecordComparison[] =>
  compareToNBARecords(getRecordAchievements(games)).filter(
    (comparison) => comparison.broken,
  )