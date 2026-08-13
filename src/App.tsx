// MVP Race Fantasy NBA Player App

import React, { useState, useEffect } from 'react'
import bcrypt from 'bcryptjs'
import { Login, GameForm, StatsDisplay, ComparisonDisplay } from './components'
import type {
  User,
  GameStats,
  CareerHighs,
  StatsSummary,
  SeasonStats,
  GameType,
} from './interfaces'
import {
  calculateCareerHighs as calcCareerHighs,
  calculateStatsSummary as calcStatsSummary,
  checkPlayoffQualification,
  organizeSeasonStats as orgSeasonStats,
} from './utils/statsCalculations'
import {
  getNextSeason,
  REGULAR_SEASON_GAME_COUNT,
  SEASONS_DATA,
} from './data/nbaData'
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
  const [progressionMessage, setProgressionMessage] = useState('')

  useEffect(() => {
    let initialTeam = ''
    let initialSeason = ''

    const initializeGameProgression = (
      parsedStats: GameStats[],
      team: string,
      season: string,
    ) => {
      const seasonGames = parsedStats.filter(
        (g) => g.season === season && g.team === team,
      )
      const regularSeasonGames = seasonGames.filter(
        (g) => g.gameType === 'regular',
      )
      const playoffGames = seasonGames.filter(
        (g) => g.gameType === 'playoffs',
      )

      if (regularSeasonGames.length >= REGULAR_SEASON_GAME_COUNT) {
        if (checkPlayoffQualification(regularSeasonGames)) {
          setCurrentGameType('playoffs')
          setCurrentGameNumber(playoffGames.length + 1)
          return
        }

        const nextSeason = getNextSeason(season)
        if (nextSeason) {
          const nextRegularGames = parsedStats.filter(
            (g) =>
              g.season === nextSeason &&
              g.team === team &&
              g.gameType === 'regular',
          )

          setSelectedSeason(nextSeason)
          setCurrentGameType('regular')
          setCurrentGameNumber(nextRegularGames.length + 1)
          setProgressionMessage(
            `${season} is complete without playoff qualification. Advanced to ${nextSeason}.`,
          )
          return
        }
      }

      setCurrentGameType('regular')
      setCurrentGameNumber(regularSeasonGames.length + 1)
    }

    try {
      const savedUsers = localStorage.getItem('users')
      if (savedUsers) {
        setUsers(JSON.parse(savedUsers))
      }
    } catch {
      setUsers([])
    }

    const savedCurrentUser = localStorage.getItem('currentUser')
    if (savedCurrentUser) {
      setCurrentUser(savedCurrentUser)
    }

    const savedTeam = localStorage.getItem('selectedTeam')
    if (savedTeam) {
      initialTeam = savedTeam
      setSelectedTeam(savedTeam)
    }

    const savedSeason = localStorage.getItem('selectedSeason')
    if (savedSeason) {
      initialSeason = savedSeason
      setSelectedSeason(savedSeason)
    }

    try {
      const savedStats = localStorage.getItem('stats')
      if (savedStats) {
        const parsedStats = JSON.parse(savedStats)
        setStats(parsedStats)
        if (initialTeam && initialSeason) {
          initializeGameProgression(parsedStats, initialTeam, initialSeason)
        }
      }
    } catch {
      setStats([])
    }

    try {
      const savedDarkMode = localStorage.getItem('darkMode')
      if (savedDarkMode) {
        setDarkMode(JSON.parse(savedDarkMode))
      }
    } catch {
      setDarkMode(false)
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

  useEffect(() => {
    localStorage.setItem('selectedTeam', selectedTeam)
  }, [selectedTeam])

  useEffect(() => {
    localStorage.setItem('selectedSeason', selectedSeason)
  }, [selectedSeason])

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

  const getTeamSeasonGames = (
    allGames: GameStats[],
    team: string,
    season: string,
  ) => allGames.filter((g) => g.season === season && g.team === team)

  const moveToNextSeason = (
    allGames: GameStats[],
    team: string,
    season: string,
  ) => {
    const nextSeason = getNextSeason(season)

    if (!nextSeason) {
      setCurrentGameType('regular')
      setCurrentGameNumber(REGULAR_SEASON_GAME_COUNT + 1)
      setProgressionMessage(
        `${season} is complete and no later season is available in the app data.`,
      )
      return
    }

    const nextRegularGames = getTeamSeasonGames(
      allGames,
      team,
      nextSeason,
    ).filter((g) => g.gameType === 'regular')

    setSelectedSeason(nextSeason)
    setCurrentGameType('regular')
    setCurrentGameNumber(nextRegularGames.length + 1)
    setProgressionMessage(
      `${season} is complete without playoff qualification. Advanced to ${nextSeason}.`,
    )
  }

  const setGameProgression = (
    allGames: GameStats[],
    team: string,
    season: string,
  ) => {
    const seasonGames = getTeamSeasonGames(allGames, team, season)
    const regularSeasonGames = seasonGames.filter(
      (g) => g.gameType === 'regular',
    )
    const playoffGames = seasonGames.filter(
      (g) => g.gameType === 'playoffs',
    )

    if (regularSeasonGames.length >= REGULAR_SEASON_GAME_COUNT) {
      if (checkPlayoffQualification(regularSeasonGames)) {
        setCurrentGameType('playoffs')
        setCurrentGameNumber(playoffGames.length + 1)
        setProgressionMessage('')
      } else {
        moveToNextSeason(allGames, team, season)
      }
      return
    }

    setCurrentGameType('regular')
    setCurrentGameNumber(regularSeasonGames.length + 1)
    setProgressionMessage('')
  }

  const login = async (
    username: string,
    password: string,
  ): Promise<boolean> => {
    try {
      const user = users.find((u) => u.username === username)
      if (!user || !user.hashedPassword) {
        return false
      }

      const isValid = await bcrypt.compare(password, user.hashedPassword)
      if (isValid) {
        setCurrentUser(username)
        localStorage.setItem('currentUser', username)
      }
      return isValid
    } catch (error) {
      console.error('Login error:', error)
      return false
    }
  }

  const logout = () => {
    setCurrentUser(null)
    localStorage.removeItem('currentUser')
  }

  const addGameStats = (games: GameStats | GameStats[]) => {
    const gamesToAdd = Array.isArray(games) ? games : [games]
    const newStats = [...stats, ...gamesToAdd]
    saveStats(newStats)

    const lastGame = gamesToAdd[gamesToAdd.length - 1]
    setSelectedTeam(lastGame.team)
    setSelectedSeason(lastGame.season)

    setGameProgression(newStats, lastGame.team, lastGame.season)
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
    const seasonsWithAwards = seasons.map((season) => {
      const seasonData = SEASONS_DATA.find(
        (s) => s.season === season.seasonYear,
      )
      return {
        ...season,
        seasonAwards: seasonData?.awards,
      }
    })
    setSeasonStats(seasonsWithAwards)
  }

  const switchToPlayoffs = () => {
    if (!selectedTeam || !selectedSeason) {
      return
    }

    const seasonGames = getTeamSeasonGames(stats, selectedTeam, selectedSeason)
    const regularSeasonGames = seasonGames.filter(
      (g) => g.gameType === 'regular',
    )

    if (!checkPlayoffQualification(regularSeasonGames)) {
      setProgressionMessage(
        `${selectedSeason} has not qualified for the playoffs. Complete an 82-game non-losing season first.`,
      )
      return
    }

    const playoffGames = seasonGames.filter((g) => g.gameType === 'playoffs')
    setCurrentGameType('playoffs')
    setCurrentGameNumber(playoffGames.length + 1)
    setProgressionMessage('')
  }

  const switchToRegularSeason = () => {
    setCurrentGameType('regular')
    const regularSeasonGames = stats.filter(
      (g) =>
        g.gameType === 'regular' &&
        g.season === selectedSeason &&
        g.team === selectedTeam,
    )
    const maxGameNumber =
      regularSeasonGames.length > 0
        ? Math.max(...regularSeasonGames.map((g) => g.gameNumber))
        : 0
    setCurrentGameNumber(maxGameNumber + 1)
    setProgressionMessage('')
  }

  const handleTeamChange = (team: string) => {
    setSelectedTeam(team)
    setCurrentGameNumber(1)
    setCurrentGameType('regular')
    setProgressionMessage('')
  }

  const handleSeasonChange = (season: string) => {
    setSelectedSeason(season)
    setCurrentGameNumber(1)
    setCurrentGameType('regular')
    setProgressionMessage('')
  }

  if (!currentUser) {
    return (
      <div className='App'>
        <main>
          <Login users={users} login={login} saveUsers={saveUsers} />
        </main>
      </div>
    )
  }

  return (
    <div className='App'>
      <header className='glass-card'>
        <h1>MVP Race NBA</h1>
        <div className='header-info'>
          <p>Welcome, {currentUser}</p>
        </div>
        <div className='header-controls'>
          <div className='game-type-switcher'>
            <button
              onClick={switchToRegularSeason}
              className={currentGameType === 'regular' ? 'active' : ''}
            >
              Regular
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
            className='dark-mode-toggle glass-card'
            aria-label='Toggle theme'
          >
            {darkMode ? '☀️' : '🌙'}
          </button>
          <button onClick={logout} className='logout-btn'>Logout</button>
        </div>
      </header>
      <main>
        <GameForm
          addGameStats={addGameStats}
          currentGameNumber={currentGameNumber}
          gameType={currentGameType}
          selectedTeam={selectedTeam}
          selectedSeason={selectedSeason}
          onTeamChange={handleTeamChange}
          onSeasonChange={handleSeasonChange}
        />
        {progressionMessage && (
          <div className='message info' role='status'>
            {progressionMessage}
          </div>
        )}
        
        <StatsDisplay
          stats={stats}
          careerHighs={careerHighs}
          statsSummary={statsSummary}
          seasonStats={seasonStats}
        />

        {selectedSeason && selectedTeam && statsSummary && (
          <ComparisonDisplay
            playerStats={statsSummary}
            seasonAwards={
              seasonStats.find((s) => s.seasonYear === selectedSeason)
                ?.seasonAwards || null
            }
            playerTeam={selectedTeam}
            season={selectedSeason}
          />
        )}
      </main>
    </div>
  )
}

export default App
