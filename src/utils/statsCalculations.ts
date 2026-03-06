import type { GameStats, SeasonStats, StatsSummary, CareerHighs, StatisticalMilestones } from '../interfaces'

export const calculateStatisticalMilestones = (games: GameStats[]): StatisticalMilestones => {
  const milestones = {
    points: { '10+': 0, '20+': 0, '30+': 0, '35+': 0, '40+': 0, '50+': 0, '60+': 0, '70+': 0, '80+': 0, '100+': 0, '100++': 0 },
    assists: { '5+': 0, '10+': 0, '15+': 0, '20+': 0, '25+': 0 },
    rebounds: { '5+': 0, '10+': 0, '15+': 0, '20+': 0, '25+': 0 },
    blocks: { '2+': 0, '5+': 0, '10+': 0 },
    steals: { '2+': 0, '5+': 0, '10+': 0 }
  }

  games.filter(game => !game.isAbsent).forEach(game => {
    // Points milestones
    if (game.points >= 10) milestones.points['10+']++
    if (game.points >= 20) milestones.points['20+']++
    if (game.points >= 30) milestones.points['30+']++
    if (game.points >= 35) milestones.points['35+']++
    if (game.points >= 40) milestones.points['40+']++
    if (game.points >= 50) milestones.points['50+']++
    if (game.points >= 60) milestones.points['60+']++
    if (game.points >= 70) milestones.points['70+']++
    if (game.points >= 80) milestones.points['80+']++
    if (game.points >= 100) milestones.points['100+']++
    if (game.points > 100) milestones.points['100++']++

    // Assists milestones
    if (game.assists >= 5) milestones.assists['5+']++
    if (game.assists >= 10) milestones.assists['10+']++
    if (game.assists >= 15) milestones.assists['15+']++
    if (game.assists >= 20) milestones.assists['20+']++
    if (game.assists >= 25) milestones.assists['25+']++

    // Rebounds milestones
    if (game.rebounds >= 5) milestones.rebounds['5+']++
    if (game.rebounds >= 10) milestones.rebounds['10+']++
    if (game.rebounds >= 15) milestones.rebounds['15+']++
    if (game.rebounds >= 20) milestones.rebounds['20+']++
    if (game.rebounds >= 25) milestones.rebounds['25+']++

    // Blocks milestones
    if (game.blocks >= 2) milestones.blocks['2+']++
    if (game.blocks >= 5) milestones.blocks['5+']++
    if (game.blocks >= 10) milestones.blocks['10+']++

    // Steals milestones
    if (game.steals >= 2) milestones.steals['2+']++
    if (game.steals >= 5) milestones.steals['5+']++
    if (game.steals >= 10) milestones.steals['10+']++
  })

  return milestones
}

export const calculateStreaks = (games: GameStats[]): { current: number; longestWin: number; longestLoss: number } => {
  let currentStreak = 0
  let longestWinStreak = 0
  let longestLossStreak = 0
  let tempWinStreak = 0
  let tempLossStreak = 0

  for (let i = games.length - 1; i >= 0; i--) {
    if (currentStreak === 0) {
      if (games[i].won) {
        currentStreak = 1
      } else {
        currentStreak = -1
      }
    } else {
      if ((currentStreak > 0 && games[i].won) || (currentStreak < 0 && !games[i].won)) {
        currentStreak = currentStreak > 0 ? currentStreak + 1 : currentStreak - 1
      } else {
        break
      }
    }
  }

  games.forEach(game => {
    if (game.won) {
      tempWinStreak++
      tempLossStreak = 0
      longestWinStreak = Math.max(longestWinStreak, tempWinStreak)
    } else {
      tempLossStreak++
      tempWinStreak = 0
      longestLossStreak = Math.max(longestLossStreak, tempLossStreak)
    }
  })

  return { current: currentStreak, longestWin: longestWinStreak, longestLoss: longestLossStreak }
}

export const calculateAverages = (games: GameStats[]) => {
  const playedGames = games.filter(game => !game.isAbsent)
  if (playedGames.length === 0) {
    return { points: 0, assists: 0, rebounds: 0, blocks: 0, steals: 0, minutes: 0 }
  }

  return {
    points: playedGames.reduce((sum, g) => sum + g.points, 0) / playedGames.length,
    assists: playedGames.reduce((sum, g) => sum + g.assists, 0) / playedGames.length,
    rebounds: playedGames.reduce((sum, g) => sum + g.rebounds, 0) / playedGames.length,
    blocks: playedGames.reduce((sum, g) => sum + g.blocks, 0) / playedGames.length,
    steals: playedGames.reduce((sum, g) => sum + g.steals, 0) / playedGames.length,
    minutes: playedGames.reduce((sum, g) => sum + g.minutes, 0) / playedGames.length,
  }
}

export const calculateCareerHighs = (allGames: GameStats[]): CareerHighs => {
  const playedGames = allGames.filter(game => !game.isAbsent)
  if (playedGames.length === 0) {
    return {
      points: 0,
      assists: 0,
      rebounds: 0,
      blocks: 0,
      steals: 0,
      minutes: 0,
      doubleDoubles: 0,
      tripleDoubles: 0,
    }
  }

  return {
    points: Math.max(...playedGames.map(g => g.points), 0),
    assists: Math.max(...playedGames.map(g => g.assists), 0),
    rebounds: Math.max(...playedGames.map(g => g.rebounds), 0),
    blocks: Math.max(...playedGames.map(g => g.blocks), 0),
    steals: Math.max(...playedGames.map(g => g.steals), 0),
    minutes: Math.max(...playedGames.map(g => g.minutes), 0),
    doubleDoubles: playedGames.filter(g => g.isDoubleDouble).length,
    tripleDoubles: playedGames.filter(g => g.isTripleDouble).length,
  }
}

export const checkPlayoffQualification = (regularSeasonGames: GameStats[]): boolean => {
  const wins = regularSeasonGames.filter(g => g.won).length
  const totalGames = regularSeasonGames.length
  const winPercentage = totalGames > 0 ? wins / totalGames : 0
  
  // Typical playoff qualification: top 10 teams in each conference (usually around 45+ wins)
  // For a simplified model, we'll use 50% win rate as the threshold
  return winPercentage >= 0.5 && totalGames >= 60 // Must play at least 60 games
}

export const organizeSeasonStats = (allGames: GameStats[]): SeasonStats[] => {
  const seasonsMap = new Map<string, GameStats[]>()

  allGames.forEach(game => {
    const seasonYear = getSeasonYear(game.date)
    if (!seasonsMap.has(seasonYear)) {
      seasonsMap.set(seasonYear, [])
    }
    seasonsMap.get(seasonYear)!.push(game)
  })

  const seasons: SeasonStats[] = []
  
  seasonsMap.forEach((games, seasonYear) => {
    const regularSeasonGames = games.filter(g => g.gameType === 'regular')
    const playoffGames = games.filter(g => g.gameType === 'playoffs')
    
    const wins = games.filter(g => g.won).length
    const losses = games.length - wins
    const playoffWins = playoffGames.filter(g => g.won).length
    const playoffLosses = playoffGames.length - playoffWins
    
    const streaks = calculateStreaks(games)
    const doubleDoubles = games.filter(g => g.isDoubleDouble).length
    const tripleDoubles = games.filter(g => g.isTripleDouble).length
    
    const careerDoubleDoubles = allGames.filter(g => g.isDoubleDouble).length
    const careerTripleDoubles = allGames.filter(g => g.isTripleDouble).length

    seasons.push({
      seasonYear,
      gamesPlayed: games.length,
      regularSeasonGames,
      playoffGames,
      wins,
      losses,
      playoffWins,
      playoffLosses,
      madePlayoffs: checkPlayoffQualification(regularSeasonGames),
      playoffSeries: [], // This would need to be implemented based on game data
      currentStreak: streaks.current,
      longestWinStreak: streaks.longestWin,
      longestLossStreak: streaks.longestLoss,
      doubleDoubles,
      tripleDoubles,
      careerDoubleDoubles,
      careerTripleDoubles,
      statisticalMilestones: calculateStatisticalMilestones(games)
    })
  })

  return seasons.sort((a, b) => b.seasonYear.localeCompare(a.seasonYear))
}

const getSeasonYear = (dateString: string): string => {
  const date = new Date(dateString)
  const year = date.getFullYear()
  const month = date.getMonth()
  
  // NBA season typically starts in October and ends in June of the following year
  if (month >= 9) { // October or later
    return `${year}-${(year + 1).toString().slice(-2)}`
  } else {
    return `${year - 1}-${year.toString().slice(-2)}`
  }
}

export const calculateStatsSummary = (allGames: GameStats[]): StatsSummary => {
  const regularSeasonGames = allGames.filter(g => g.gameType === 'regular')
  const playoffGames = allGames.filter(g => g.gameType === 'playoffs')
  
  const wins = allGames.filter(g => g.won).length
  const losses = allGames.length - wins
  const playoffWins = playoffGames.filter(g => g.won).length
  const playoffLosses = playoffGames.length - playoffWins
  
  const streaks = calculateStreaks(allGames)
  
  return {
    wins,
    losses,
    playoffWins,
    playoffLosses,
    currentStreak: streaks.current,
    longestWinStreak: streaks.longestWin,
    longestLossStreak: streaks.longestLoss,
    winPercentage: allGames.length > 0 ? wins / allGames.length : 0,
    playoffWinPercentage: playoffGames.length > 0 ? playoffWins / playoffGames.length : 0,
    averages: calculateAverages(allGames),
    seasonAverages: calculateAverages(regularSeasonGames),
    playoffAverages: calculateAverages(playoffGames)
  }
}
