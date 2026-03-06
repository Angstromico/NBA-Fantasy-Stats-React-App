export interface NBATeam {
  id: string
  name: string
  city: string
  conference: 'Eastern' | 'Western'
  division: string
}

export interface SeasonAwards {
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

export interface Game {
  date: string
  opponent: string
  isHome: boolean
  isPlayoff: boolean
  playoffRound?: number
}

export interface TeamSchedule {
  teamId: string
  season: string
  games: Game[]
}

export interface SeasonData {
  season: string
  awards: SeasonAwards
  schedules: TeamSchedule[]
}

// NBA Teams
export const NBA_TEAMS: NBATeam[] = [
  // Eastern Conference - Atlantic
  { id: 'bos', name: 'Celtics', city: 'Boston', conference: 'Eastern', division: 'Atlantic' },
  { id: 'nyk', name: 'Knicks', city: 'New York', conference: 'Eastern', division: 'Atlantic' },
  { id: 'bkn', name: 'Nets', city: 'Brooklyn', conference: 'Eastern', division: 'Atlantic' },
  { id: 'phi', name: '76ers', city: 'Philadelphia', conference: 'Eastern', division: 'Atlantic' },
  { id: 'tor', name: 'Raptors', city: 'Toronto', conference: 'Eastern', division: 'Atlantic' },
  
  // Eastern Conference - Central
  { id: 'cle', name: 'Cavaliers', city: 'Cleveland', conference: 'Eastern', division: 'Central' },
  { id: 'chi', name: 'Bulls', city: 'Chicago', conference: 'Eastern', division: 'Central' },
  { id: 'ind', name: 'Pacers', city: 'Indiana', conference: 'Eastern', division: 'Central' },
  { id: 'det', name: 'Pistons', city: 'Detroit', conference: 'Eastern', division: 'Central' },
  { id: 'mil', name: 'Bucks', city: 'Milwaukee', conference: 'Eastern', division: 'Central' },
  
  // Eastern Conference - Southeast
  { id: 'mia', name: 'Heat', city: 'Miami', conference: 'Eastern', division: 'Southeast' },
  { id: 'atl', name: 'Hawks', city: 'Atlanta', conference: 'Eastern', division: 'Southeast' },
  { id: 'cha', name: 'Hornets', city: 'Charlotte', conference: 'Eastern', division: 'Southeast' },
  { id: 'was', name: 'Wizards', city: 'Washington', conference: 'Eastern', division: 'Southeast' },
  { id: 'orl', name: 'Magic', city: 'Orlando', conference: 'Eastern', division: 'Southeast' },
  
  // Western Conference - Northwest
  { id: 'okc', name: 'Thunder', city: 'Oklahoma City', conference: 'Western', division: 'Northwest' },
  { id: 'den', name: 'Nuggets', city: 'Denver', conference: 'Western', division: 'Northwest' },
  { id: 'por', name: 'Trail Blazers', city: 'Portland', conference: 'Western', division: 'Northwest' },
  { id: 'min', name: 'Timberwolves', city: 'Minnesota', conference: 'Western', division: 'Northwest' },
  { id: 'utah', name: 'Jazz', city: 'Utah', conference: 'Western', division: 'Northwest' },
  
  // Western Conference - Pacific
  { id: 'gsw', name: 'Warriors', city: 'Golden State', conference: 'Western', division: 'Pacific' },
  { id: 'lal', name: 'Lakers', city: 'LA', conference: 'Western', division: 'Pacific' },
  { id: 'lac', name: 'Clippers', city: 'LA', conference: 'Western', division: 'Pacific' },
  { id: 'phx', name: 'Suns', city: 'Phoenix', conference: 'Western', division: 'Pacific' },
  { id: 'sac', name: 'Kings', city: 'Sacramento', conference: 'Western', division: 'Pacific' },
  
  // Western Conference - Southwest
  { id: 'sas', name: 'Spurs', city: 'San Antonio', conference: 'Western', division: 'Southwest' },
  { id: 'hou', name: 'Rockets', city: 'Houston', conference: 'Western', division: 'Southwest' },
  { id: 'dal', name: 'Mavericks', city: 'Dallas', conference: 'Western', division: 'Southwest' },
  { id: 'mem', name: 'Grizzlies', city: 'Memphis', conference: 'Western', division: 'Southwest' },
  { id: 'nop', name: 'Pelicans', city: 'New Orleans', conference: 'Western', division: 'Southwest' }
]

// Helper function to generate realistic dates for a season
const generateSeasonDates = (seasonStartYear: number): string[] => {
  const dates: string[] = []
  const startDate = new Date(seasonStartYear, 9, 25) // Late October
  const endDate = new Date(seasonStartYear + 1, 3, 15) // Mid April
  
  for (let d = new Date(startDate); d <= endDate; d.setDate(d.getDate() + 2)) {
    dates.push(d.toISOString().split('T')[0])
  }
  
  return dates
}

// Helper function to generate a realistic schedule for a team
const generateTeamSchedule = (teamId: string, season: string, allTeams: NBATeam[]): Game[] => {
  const team = allTeams.find(t => t.id === teamId)!
  const conferenceTeams = allTeams.filter(t => t.conference === team.conference && t.id !== teamId)
  const otherConferenceTeams = allTeams.filter(t => t.conference !== team.conference)
  const divisionTeams = allTeams.filter(t => t.division === team.division && t.id !== teamId)
  
  const games: Game[] = []
  const dates = generateSeasonDates(parseInt(season.split('-')[0]))
  
  // Division games (4 times each)
  divisionTeams.forEach(opp => {
    for (let i = 0; i < 4; i++) {
      if (dates.length > 0) {
        games.push({
          date: dates.shift()!,
          opponent: `${opp.city} ${opp.name}`,
          isHome: i % 2 === 0,
          isPlayoff: false
        })
      }
    }
  })
  
  // Conference games (3-4 times each)
  conferenceTeams.forEach(opp => {
    const times = Math.random() > 0.5 ? 4 : 3
    for (let i = 0; i < times; i++) {
      if (dates.length > 0) {
        games.push({
          date: dates.shift()!,
          opponent: `${opp.city} ${opp.name}`,
          isHome: i % 2 === 0,
          isPlayoff: false
        })
      }
    }
  })
  
  // Other conference games (2 times each)
  otherConferenceTeams.forEach(opp => {
    for (let i = 0; i < 2; i++) {
      if (dates.length > 0) {
        games.push({
          date: dates.shift()!,
          opponent: `${opp.city} ${opp.name}`,
          isHome: i % 2 === 0,
          isPlayoff: false
        })
      }
    }
  })
  
  // Sort games by date and return first 82
  return games.sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime()).slice(0, 82)
}

// Generate playoff schedule
const generatePlayoffSchedule = (teamId: string, season: string, awards: SeasonAwards, allTeams: NBATeam[]): Game[] => {
  const games: Game[] = []
  const team = allTeams.find(t => t.id === teamId)!
  
  // First round (Best of 7)
  const firstRoundDates = ['2025-04-20', '2025-04-22', '2025-04-24', '2025-04-26', '2025-04-28', '2025-04-30', '2025-05-02']
  firstRoundDates.forEach((date, i) => {
    games.push({
      date,
      opponent: 'Playoffs Round 1 Opponent',
      isHome: i % 2 === 0,
      isPlayoff: true,
      playoffRound: 1
    })
  })
  
  // Conference Finals (if team advances)
  const confFinalsDates = ['2025-05-08', '2025-05-10', '2025-05-12', '2025-05-14', '2025-05-16', '2025-05-18', '2025-05-20']
  confFinalsDates.forEach((date, i) => {
    games.push({
      date,
      opponent: 'Conference Finals Opponent',
      isHome: i % 2 === 0,
      isPlayoff: true,
      playoffRound: 2
    })
  })
  
  // NBA Finals (if team advances)
  const finalsDates = ['2025-05-25', '2025-05-27', '2025-05-29', '2025-05-31', '2025-06-02', '2025-06-04', '2025-06-06']
  finalsDates.forEach((date, i) => {
    const finalOpponent = awards.champion.team === `${team.city} ${team.name}` 
      ? getFinalsOpponent(team.conference, season)
      : awards.champion.team
    
    games.push({
      date,
      opponent: finalOpponent,
      isHome: i % 2 === 0,
      isPlayoff: true,
      playoffRound: 3
    })
  })
  
  return games
}

const getFinalsOpponent = (conference: 'Eastern' | 'Western', season: string): string => {
  // This would ideally be based on actual finals data
  // For now, return a placeholder
  return conference === 'Eastern' ? 'Western Conference Champion' : 'Eastern Conference Champion'
}

// Season data with awards (2008-2025)
export const SEASONS_DATA: SeasonData[] = [
  {
    season: '2008-2009',
    awards: {
      mvp: { player: 'LeBron James', team: 'Cleveland Cavaliers' },
      champion: { team: 'Los Angeles Lakers', record: '65-17' },
      scoringChampion: { player: 'Dwyane Wade', team: 'Miami Heat', ppg: 30.2 },
      defensivePlayerOfYear: { player: 'Dwight Howard', team: 'Orlando Magic' },
      winningestTeam: { team: 'Cleveland Cavaliers', record: '66-16', wins: 66 }
    },
    schedules: []
  },
  {
    season: '2009-2010',
    awards: {
      mvp: { player: 'LeBron James', team: 'Cleveland Cavaliers' },
      champion: { team: 'Los Angeles Lakers', record: '57-25' },
      scoringChampion: { player: 'Kevin Durant', team: 'Oklahoma City Thunder', ppg: 30.1 },
      defensivePlayerOfYear: { player: 'Dwight Howard', team: 'Orlando Magic' },
      winningestTeam: { team: 'Cleveland Cavaliers', record: '61-21', wins: 61 }
    },
    schedules: []
  },
  {
    season: '2010-2011',
    awards: {
      mvp: { player: 'Derrick Rose', team: 'Chicago Bulls' },
      champion: { team: 'Dallas Mavericks', record: '57-25' },
      scoringChampion: { player: 'Kevin Durant', team: 'Oklahoma City Thunder', ppg: 27.7 },
      defensivePlayerOfYear: { player: 'Dwight Howard', team: 'Orlando Magic' },
      winningestTeam: { team: 'San Antonio Spurs', record: '61-21', wins: 61 }
    },
    schedules: []
  },
  {
    season: '2011-2012',
    awards: {
      mvp: { player: 'LeBron James', team: 'Miami Heat' },
      champion: { team: 'Miami Heat', record: '46-20' },
      scoringChampion: { player: 'Kevin Durant', team: 'Oklahoma City Thunder', ppg: 28.0 },
      defensivePlayerOfYear: { player: 'Tyson Chandler', team: 'New York Knicks' },
      winningestTeam: { team: 'San Antonio Spurs', record: '50-16', wins: 50 }
    },
    schedules: []
  },
  {
    season: '2012-2013',
    awards: {
      mvp: { player: 'LeBron James', team: 'Miami Heat' },
      champion: { team: 'Miami Heat', record: '66-16' },
      scoringChampion: { player: 'Carmelo Anthony', team: 'New York Knicks', ppg: 28.7 },
      defensivePlayerOfYear: { player: 'Marc Gasol', team: 'Memphis Grizzlies' },
      winningestTeam: { team: 'Miami Heat', record: '66-16', wins: 66 }
    },
    schedules: []
  },
  {
    season: '2013-2014',
    awards: {
      mvp: { player: 'Kevin Durant', team: 'Oklahoma City Thunder' },
      champion: { team: 'San Antonio Spurs', record: '62-20' },
      scoringChampion: { player: 'Kevin Durant', team: 'Oklahoma City Thunder', ppg: 32.0 },
      defensivePlayerOfYear: { player: 'Joakim Noah', team: 'Chicago Bulls' },
      winningestTeam: { team: 'San Antonio Spurs', record: '62-20', wins: 62 }
    },
    schedules: []
  },
  {
    season: '2014-2015',
    awards: {
      mvp: { player: 'Stephen Curry', team: 'Golden State Warriors' },
      champion: { team: 'Golden State Warriors', record: '67-15' },
      scoringChampion: { player: 'Russell Westbrook', team: 'Oklahoma City Thunder', ppg: 28.1 },
      defensivePlayerOfYear: { player: 'Kawhi Leonard', team: 'San Antonio Spurs' },
      winningestTeam: { team: 'Golden State Warriors', record: '67-15', wins: 67 }
    },
    schedules: []
  },
  {
    season: '2015-2016',
    awards: {
      mvp: { player: 'Stephen Curry', team: 'Golden State Warriors' },
      champion: { team: 'Cleveland Cavaliers', record: '57-25' },
      scoringChampion: { player: 'Stephen Curry', team: 'Golden State Warriors', ppg: 30.1 },
      defensivePlayerOfYear: { player: 'Kawhi Leonard', team: 'San Antonio Spurs' },
      winningestTeam: { team: 'Golden State Warriors', record: '73-9', wins: 73 }
    },
    schedules: []
  },
  {
    season: '2016-2017',
    awards: {
      mvp: { player: 'Russell Westbrook', team: 'Oklahoma City Thunder' },
      champion: { team: 'Golden State Warriors', record: '67-15' },
      scoringChampion: { player: 'Russell Westbrook', team: 'Oklahoma City Thunder', ppg: 31.6 },
      defensivePlayerOfYear: { player: 'Draymond Green', team: 'Golden State Warriors' },
      winningestTeam: { team: 'Golden State Warriors', record: '67-15', wins: 67 }
    },
    schedules: []
  },
  {
    season: '2017-2018',
    awards: {
      mvp: { player: 'James Harden', team: 'Houston Rockets' },
      champion: { team: 'Golden State Warriors', record: '58-24' },
      scoringChampion: { player: 'James Harden', team: 'Houston Rockets', ppg: 30.4 },
      defensivePlayerOfYear: { player: 'Rudy Gobert', team: 'Utah Jazz' },
      winningestTeam: { team: 'Houston Rockets', record: '65-17', wins: 65 }
    },
    schedules: []
  },
  {
    season: '2018-2019',
    awards: {
      mvp: { player: 'Giannis Antetokounmpo', team: 'Milwaukee Bucks' },
      champion: { team: 'Toronto Raptors', record: '58-24' },
      scoringChampion: { player: 'James Harden', team: 'Houston Rockets', ppg: 36.1 },
      defensivePlayerOfYear: { player: 'Rudy Gobert', team: 'Utah Jazz' },
      winningestTeam: { team: 'Milwaukee Bucks', record: '60-22', wins: 60 }
    },
    schedules: []
  },
  {
    season: '2019-2020',
    awards: {
      mvp: { player: 'Giannis Antetokounmpo', team: 'Milwaukee Bucks' },
      champion: { team: 'Los Angeles Lakers', record: '52-19' },
      scoringChampion: { player: 'James Harden', team: 'Houston Rockets', ppg: 34.3 },
      defensivePlayerOfYear: { player: 'Giannis Antetokounmpo', team: 'Milwaukee Bucks' },
      winningestTeam: { team: 'Milwaukee Bucks', record: '56-17', wins: 56 }
    },
    schedules: []
  },
  {
    season: '2020-2021',
    awards: {
      mvp: { player: 'Nikola Jokić', team: 'Denver Nuggets' },
      champion: { team: 'Milwaukee Bucks', record: '46-26' },
      scoringChampion: { player: 'Stephen Curry', team: 'Golden State Warriors', ppg: 32.0 },
      defensivePlayerOfYear: { player: 'Rudy Gobert', team: 'Utah Jazz' },
      winningestTeam: { team: 'Utah Jazz', record: '52-20', wins: 52 }
    },
    schedules: []
  },
  {
    season: '2021-2022',
    awards: {
      mvp: { player: 'Nikola Jokić', team: 'Denver Nuggets' },
      champion: { team: 'Golden State Warriors', record: '53-29' },
      scoringChampion: { player: 'Joel Embiid', team: 'Philadelphia 76ers', ppg: 30.6 },
      defensivePlayerOfYear: { player: 'Marcus Smart', team: 'Boston Celtics' },
      winningestTeam: { team: 'Phoenix Suns', record: '64-18', wins: 64 }
    },
    schedules: []
  },
  {
    season: '2022-2023',
    awards: {
      mvp: { player: 'Joel Embiid', team: 'Philadelphia 76ers' },
      champion: { team: 'Denver Nuggets', record: '53-29' },
      scoringChampion: { player: 'Joel Embiid', team: 'Philadelphia 76ers', ppg: 33.4 },
      defensivePlayerOfYear: { player: 'Jaren Jackson Jr.', team: 'Memphis Grizzlies' },
      winningestTeam: { team: 'Milwaukee Bucks', record: '58-24', wins: 58 }
    },
    schedules: []
  },
  {
    season: '2023-2024',
    awards: {
      mvp: { player: 'Nikola Jokić', team: 'Denver Nuggets' },
      champion: { team: 'Boston Celtics', record: '64-18' },
      scoringChampion: { player: 'Luka Dončić', team: 'Dallas Mavericks', ppg: 32.7 },
      defensivePlayerOfYear: { player: 'Rudy Gobert', team: 'Minnesota Timberwolves' },
      winningestTeam: { team: 'Boston Celtics', record: '64-18', wins: 64 }
    },
    schedules: []
  },
  {
    season: '2024-2025',
    awards: {
      mvp: { player: 'Nikola Jokić', team: 'Denver Nuggets' },
      champion: { team: 'Golden State Warriors', record: '58-24' },
      scoringChampion: { player: 'Luka Dončić', team: 'Dallas Mavericks', ppg: 31.5 },
      defensivePlayerOfYear: { player: 'Victor Wembanyama', team: 'San Antonio Spurs' },
      winningestTeam: { team: 'Golden State Warriors', record: '58-24', wins: 58 }
    },
    schedules: []
  }
]

// Generate schedules for all teams and seasons
export const generateAllSchedules = (): SeasonData[] => {
  return SEASONS_DATA.map(seasonData => ({
    ...seasonData,
    schedules: NBA_TEAMS.map(team => ({
      teamId: team.id,
      season: seasonData.season,
      games: [
        ...generateTeamSchedule(team.id, seasonData.season, NBA_TEAMS),
        ...generatePlayoffSchedule(team.id, seasonData.season, seasonData.awards, NBA_TEAMS)
      ]
    }))
  }))
}

// Get schedule for specific team and season
export const getTeamSchedule = (teamId: string, season: string): Game[] => {
  const allData = generateAllSchedules()
  const seasonData = allData.find(s => s.season === season)
  const teamSchedule = seasonData?.schedules.find(s => s.teamId === teamId)
  return teamSchedule?.games || []
}

// Get available seasons
export const getAvailableSeasons = (): string[] => {
  return SEASONS_DATA.map(s => s.season)
}
