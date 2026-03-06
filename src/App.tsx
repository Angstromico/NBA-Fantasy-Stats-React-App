// MVP Race Fantasy NBA Player App

import React, { useState, useEffect } from 'react'
import { Login, GameForm, StatsDisplay, ComparisonDisplay } from './components'
import type { User, GameStats, CareerHighs, StatsSummary, SeasonStats, GameType } from './interfaces'
import { 
  calculateCareerHighs as calcCareerHighs, 
  calculateStatsSummary as calcStatsSummary, 
  organizeSeasonStats as orgSeasonStats
} from './utils/statsCalculations'
import { getAvailableSeasons, SEASONS_DATA } from './data/nbaData'
import './App.css'

const App: React.FC = () => {
  const [users, setUsers] = useState<User[]>([])
  const [currentUser, setCurrentUser] = useState<string | null>(null)
  const [stats, setStats] = useState<GameStats[]>([])
  const [careerHighs, setCareerHighs] = useState<CareerHighs | null>(null)
  const [statsSummary, setStatsSummary] = useState<StatsSummary | null>(null)
  const [seasonStats, setSeasonStats] = useState<SeasonStats[]>([])
  const [currentGameType, setCurrentGameType] = useState<GameType>('regular')
  const [currentGameNumber, setCurrentGameNumber] = useState(1)
  const [darkMode, setDarkMode] = useState(false)
  const [selectedTeam, setSelectedTeam] = useState('')
  const [selectedSeason, setSelectedSeason] = useState('')

  useEffect(() => {
    const savedUsers = localStorage.getItem('users')
    if (savedUsers) {
      setUsers(JSON.parse(savedUsers))
    }

    const savedCurrentUser = localStorage.getItem('currentUser')
    if (savedCurrentUser) {
      setCurrentUser(savedCurrentUser)
    }

    const savedStats = localStorage.getItem('stats')
    if (savedStats) {
      const parsedStats = JSON.parse(savedStats)
      setStats(parsedStats)
      
      // Calculate game numbers and set current game type
      const regularSeasonGames = parsedStats.filter((g: GameStats) => g.gameType === 'regular')
      const playoffGames = parsedStats.filter((g: GameStats) => g.gameType === 'playoffs')
      
      if (regularSeasonGames.length > 0) {
        const maxRegularGameNumber = Math.max(...regularSeasonGames.map((g: GameStats) => g.gameNumber))
        setCurrentGameNumber(maxRegularGameNumber + 1)
      }
      
      if (playoffGames.length > 0) {
        setCurrentGameType('playoffs')
      }
    }

    // Load dark mode preference
    const savedDarkMode = localStorage.getItem('darkMode')
    if (savedDarkMode) {
      setDarkMode(JSON.parse(savedDarkMode))
    }
  }, [])

  useEffect(() => {
    if (stats.length) {
      calculateCareerHighs(stats)
      calculateStatsSummary(stats)
      organizeSeasonStats(stats)
    }
  }, [stats])

  useEffect(() => {
    // Apply dark mode class to body
    if (darkMode) {
      document.body.classList.add('dark-mode')
    } else {
      document.body.classList.remove('dark-mode')
    }
    // Save dark mode preference
    localStorage.setItem('darkMode', JSON.stringify(darkMode))
  }, [darkMode])

  const toggleDarkMode = () => {
    setDarkMode(!darkMode)
  }

  const saveUsers = (newUsers: User[]) => {
    setUsers(newUsers)
    localStorage.setItem('users', JSON.stringify(newUsers))
  }

  const saveStats = (newStats: GameStats[]) => {
    setStats(newStats)
    localStorage.setItem('stats', JSON.stringify(newStats))
  }

  const login = (username: string, password: string) => {
    const user = users.find((u) => u.username === username && u.password === password)
    if (user) {
      setCurrentUser(username)
      localStorage.setItem('currentUser', username)
    } else {
      alert('Invalid username or password')
    }
  }

  const logout = () => {
    setCurrentUser(null)
    localStorage.removeItem('currentUser')
  }

  const addGameStats = (game: GameStats) => {
    const newStats = [...stats, game]
    saveStats(newStats)
    
    // Update game numbers
    const currentSeasonGames = newStats.filter(g => g.season === selectedSeason && g.team === selectedTeam)
    if (game.gameType === 'regular') {
      setCurrentGameNumber(currentSeasonGames.filter(g => g.gameType === 'regular').length + 1)
    }
    
    // Check if we should switch to playoffs (after 82 regular season games)
    const regularSeasonGames = currentSeasonGames.filter(g => g.gameType === 'regular')
    if (regularSeasonGames.length >= 82) {
      setCurrentGameType('playoffs')
      setCurrentGameNumber(1)
    }
  }

  const calculateCareerHighs = (games: GameStats[]) => {
    const highs = calcCareerHighs(games)
    setCareerHighs(highs)
  }

  const calculateStatsSummary = (games: GameStats[]) => {
    const summary = calcStatsSummary(games)
    setStatsSummary(summary)
  }

  const organizeSeasonStats = (games: GameStats[]) => {
    const seasons = orgSeasonStats(games)
    // Add season awards data
    const seasonsWithAwards = seasons.map(season => {
      const seasonData = SEASONS_DATA.find(s => s.season === season.seasonYear)
      return {
        ...season,
        seasonAwards: seasonData?.awards
      }
    })
    setSeasonStats(seasonsWithAwards)
  }

  const switchToPlayoffs = () => {
    setCurrentGameType('playoffs')
    setCurrentGameNumber(1)
  }

  const switchToRegularSeason = () => {
    setCurrentGameType('regular')
    const regularSeasonGames = stats.filter(g => g.gameType === 'regular' && g.season === selectedSeason && g.team === selectedTeam)
    const maxGameNumber = regularSeasonGames.length > 0 
      ? Math.max(...regularSeasonGames.map(g => g.gameNumber)) 
      : 0
    setCurrentGameNumber(maxGameNumber + 1)
  }

  const handleTeamChange = (team: string) => {
    setSelectedTeam(team)
    setCurrentGameNumber(1)
    setCurrentGameType('regular')
  }

  const handleSeasonChange = (season: string) => {
    setSelectedSeason(season)
    setCurrentGameNumber(1)
    setCurrentGameType('regular')
  }

  if (!currentUser) {
    return <Login users={users} login={login} saveUsers={saveUsers} />
  }

  return (
    <div className='App'>
      <header>
        <h1>MVP Race Fantasy NBA Player</h1>
        <p>Welcome, {currentUser}</p>
        <div className="header-controls">
          <div className="game-type-switcher">
            <button 
              onClick={switchToRegularSeason}
              className={currentGameType === 'regular' ? 'active' : ''}
            >
              Regular Season
            </button>
            <button 
              onClick={switchToPlayoffs}
              className={currentGameType === 'playoffs' ? 'active' : ''}
            >
              Playoffs
            </button>
          </div>
          <button 
            onClick={toggleDarkMode}
            className="dark-mode-toggle"
            aria-label="Toggle dark mode"
          >
            {darkMode ? '☀️' : '🌙'}
          </button>
          <button onClick={logout}>Logout</button>
        </div>
      </header>
      <GameForm 
        addGameStats={addGameStats} 
        currentGameNumber={currentGameNumber}
        gameType={currentGameType}
        selectedTeam={selectedTeam}
        selectedSeason={selectedSeason}
        onTeamChange={handleTeamChange}
        onSeasonChange={handleSeasonChange}
      />
      <StatsDisplay 
        stats={stats} 
        careerHighs={careerHighs} 
        statsSummary={statsSummary}
        seasonStats={seasonStats}
      />
      {selectedSeason && selectedTeam && statsSummary && (
        <ComparisonDisplay 
          playerStats={statsSummary}
          seasonAwards={seasonStats.find(s => s.seasonYear === selectedSeason)?.seasonAwards || null}
          playerTeam={selectedTeam}
          season={selectedSeason}
        />
      )}
    </div>
  )
}

export default App
