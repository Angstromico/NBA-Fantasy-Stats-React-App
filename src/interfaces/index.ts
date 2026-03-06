type User = {
  username: string
  password: string
}

type Team = {
  id: string
  name: string
  city: string
  conference: 'Eastern' | 'Western'
  division: string
}

type AbsenceType = 'none' | 'rest' | 'injury' | 'personal' | 'suspension'

type GameType = 'regular' | 'playoffs'

type PlayoffSeries = {
  round: number
  opponent: string
  gamesWon: number
  gamesLost: number
  isComplete: boolean
}

type GameStats = {
  id: string
  date: string
  team: string
  opponent: string
  gameNumber: number
  gameType: GameType
  absenceType: AbsenceType
  isAbsent: boolean
  points: number
  assists: number
  rebounds: number
  blocks: number
  steals: number
  minutes: number
  won: boolean
  isDoubleDouble: boolean
  isTripleDouble: boolean
  playoffSeries?: PlayoffSeries
  season: string
}

type SeasonAwards = {
  mvp: {
    player: string
    team: string
  }
  champion: {
    team: string
    record: string
  }
  scoringChampion: {
    player: string
    team: string
    ppg: number
  }
  defensivePlayerOfYear: {
    player: string
    team: string
  }
  winningestTeam: {
    team: string
    record: string
    wins: number
  }
}

type SeasonStats = {
  seasonYear: string
  gamesPlayed: number
  regularSeasonGames: GameStats[]
  playoffGames: GameStats[]
  wins: number
  losses: number
  playoffWins: number
  playoffLosses: number
  madePlayoffs: boolean
  playoffSeries: PlayoffSeries[]
  currentStreak: number
  longestWinStreak: number
  longestLossStreak: number
  doubleDoubles: number
  tripleDoubles: number
  careerDoubleDoubles: number
  careerTripleDoubles: number
  statisticalMilestones: {
    points: {
      '10+': number
      '20+': number
      '30+': number
      '35+': number
      '40+': number
      '50+': number
      '60+': number
      '70+': number
      '80+': number
      '100+': number
      '100++': number
    }
    assists: {
      '5+': number
      '10+': number
      '15+': number
      '20+': number
      '25+': number
    }
    rebounds: {
      '5+': number
      '10+': number
      '15+': number
      '20+': number
      '25+': number
    }
    blocks: {
      '2+': number
      '5+': number
      '10+': number
    }
    steals: {
      '2+': number
      '5+': number
      '10+': number
    }
  }
  seasonAwards?: SeasonAwards
}

type CareerHighs = {
  points: number
  assists: number
  rebounds: number
  blocks: number
  steals: number
  minutes: number
  doubleDoubles: number
  tripleDoubles: number
}

type StatsSummary = {
  wins: number
  losses: number
  playoffWins: number
  playoffLosses: number
  currentStreak: number
  longestWinStreak: number
  longestLossStreak: number
  winPercentage: number
  playoffWinPercentage: number
  averages: {
    points: number
    assists: number
    rebounds: number
    blocks: number
    steals: number
    minutes: number
  }
  seasonAverages: {
    points: number
    assists: number
    rebounds: number
    blocks: number
    steals: number
    minutes: number
  }
  playoffAverages: {
    points: number
    assists: number
    rebounds: number
    blocks: number
    steals: number
    minutes: number
  }
}

export type { User, Team, GameStats, SeasonStats, CareerHighs, StatsSummary, AbsenceType, GameType, PlayoffSeries, SeasonAwards }
export type StatisticalMilestones = SeasonStats['statisticalMilestones']
