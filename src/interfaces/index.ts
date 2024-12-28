type User = {
  username: string
  password: string
}

type GameStats = {
  points: number
  assists: number
  rebounds: number
  blocks: number
  steals: number
  won: boolean
}

type CareerHighs = {
  points: number
  assists: number
  rebounds: number
  blocks: number
  steals: number
}

type StatsSummary = {
  wins: number
  losses: number
  averages: {
    points: number
    assists: number
    rebounds: number
    blocks: number
    steals: number
  }
}

export type { User, GameStats, CareerHighs, StatsSummary }
