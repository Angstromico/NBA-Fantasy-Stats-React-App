// MVP Race Fantasy NBA Player App

import React, { useState, useEffect, useMemo } from 'react'
import bcrypt from 'bcryptjs'
import {
  Login,
  GameForm,
  StatsDisplay,
  ComparisonDisplay,
  StatsSummaryPage,
  RecordsDisplay,
  AllTimeLeaderboards,
} from './components'
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
  getSeasonYear,
  organizeSeasonStats as orgSeasonStats,
} from './utils/statsCalculations'
import { getBrokenRecords } from './utils/recordCalculations'
import type { RecordComparison } from './utils/recordCalculations'
import { computeTopTwentyEntrances } from './utils/leaderboardCalculations'
import type { TopTwentyEntrance } from './utils/leaderboardCalculations'
import {
  NBA_TEAMS,
  getAvailableSeasons,
  getNextSeason,
  getTeamPlayoffSchedule,
  getTeamRegularSeasonSchedule,
  PLAYOFF_SERIES_WIN_COUNT,
  REGULAR_SEASON_GAME_COUNT,
  SEASONS_DATA,
} from './data/nbaData'
import './App.css'

type PlayoffProgression =
  | { status: 'not-started'; nextGameNumber: number }
  | { status: 'active'; nextGameNumber: number; round: number }
  | { status: 'eliminated'; round: number }
  | { status: 'complete' }

type AppView = 'tracker' | 'summary' | 'records'

const getTeamId = (teamName: string) =>
  NBA_TEAMS.find((team) => `${team.city} ${team.name}` === teamName)?.id || ''

const getPlayoffRoundForGame = (
  team: string,
  season: string,
  gameNumber: number,
) => {
  const schedule = getTeamPlayoffSchedule(getTeamId(team), season)
  return schedule[gameNumber - 1]?.playoffRound || Math.ceil(gameNumber / 7)
}

const getPlayoffProgression = (
  allGames: GameStats[],
  team: string,
  season: string,
): PlayoffProgression => {
  const schedule = getTeamPlayoffSchedule(getTeamId(team), season)
  const playoffGames = allGames
    .filter(
      (game) =>
        game.team === team &&
        game.season === season &&
        game.gameType === 'playoffs',
    )
    .sort((a, b) => a.gameNumber - b.gameNumber)
  const playoffRounds = Array.from(
    new Set(schedule.map((game) => game.playoffRound).filter(Boolean)),
  ) as number[]

  if (playoffGames.length === 0) {
    return { status: 'not-started', nextGameNumber: 1 }
  }

  for (const round of playoffRounds) {
    const roundStartIndex = schedule.findIndex(
      (game) => game.playoffRound === round,
    )
    const roundGames = playoffGames.filter(
      (game) => getPlayoffRoundForGame(team, season, game.gameNumber) === round,
    )
    const wins = roundGames.filter((game) => game.won).length
    const losses = roundGames.length - wins

    if (losses >= PLAYOFF_SERIES_WIN_COUNT) {
      return { status: 'eliminated', round }
    }

    if (wins >= PLAYOFF_SERIES_WIN_COUNT) {
      continue
    }

    return {
      status: 'active',
      round,
      nextGameNumber: roundStartIndex + roundGames.length + 1,
    }
  }

  return { status: 'complete' }
}

const filterPlayableGames = (
  existingGames: GameStats[],
  incomingGames: GameStats[],
) => {
  const acceptedGames: GameStats[] = []
  const eliminatedSeasons = new Set<string>()

  incomingGames.forEach((game) => {
    if (game.gameType !== 'playoffs') {
      acceptedGames.push(game)
      return
    }

    const seasonKey = `${game.team}:${game.season}`
    if (eliminatedSeasons.has(seasonKey)) {
      return
    }

    const playableGames = [...existingGames, ...acceptedGames]
    const currentProgression = getPlayoffProgression(
      playableGames,
      game.team,
      game.season,
    )

    if (
      currentProgression.status === 'eliminated' ||
      currentProgression.status === 'complete'
    ) {
      eliminatedSeasons.add(seasonKey)
      return
    }

    const gameRound = getPlayoffRoundForGame(
      game.team,
      game.season,
      game.gameNumber,
    )

    if (currentProgression.status === 'not-started' && gameRound !== 1) {
      return
    }

    if (
      currentProgression.status === 'active' &&
      gameRound !== currentProgression.round
    ) {
      return
    }

    acceptedGames.push(game)

    const nextProgression = getPlayoffProgression(
      [...existingGames, ...acceptedGames],
      game.team,
      game.season,
    )

    if (nextProgression.status === 'eliminated') {
      eliminatedSeasons.add(seasonKey)
    }
  })

  return acceptedGames
}

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
  const [recordsCongrats, setRecordsCongrats] = useState<RecordComparison[]>([])
  const [topTwentyCongrats, setTopTwentyCongrats] = useState<TopTwentyEntrance[]>([])
  const [appView, setAppView] = useState<AppView>('tracker')

  const currentSeasonGames = useMemo(() => {
    if (!selectedSeason) return []
    const seasonMatches = stats.filter((game) => {
      const seasonYear =
        game.season || (game.date ? getSeasonYear(game.date) : 'unknown')
      return seasonYear === selectedSeason
    })
    const teamMatches = seasonMatches.filter(
      (game) => !selectedTeam || game.team === selectedTeam,
    )
    return teamMatches.length > 0 ? teamMatches : seasonMatches
  }, [stats, selectedSeason, selectedTeam])

  const currentSeasonSummary = useMemo(() => {
    return calcStatsSummary(currentSeasonGames)
  }, [currentSeasonGames])

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

      if (regularSeasonGames.length >= REGULAR_SEASON_GAME_COUNT) {
        if (checkPlayoffQualification(regularSeasonGames)) {
          const playoffProgression = getPlayoffProgression(
            parsedStats,
            team,
            season,
          )

          if (playoffProgression.status === 'eliminated') {
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
                `${season} playoff run ended in round ${playoffProgression.round}. Advanced to ${nextSeason}.`,
              )
              return
            }

            setCurrentGameType('regular')
            setCurrentGameNumber(REGULAR_SEASON_GAME_COUNT + 1)
            setProgressionMessage(
              `${season} playoff run ended in round ${playoffProgression.round}. No later season is available in the app data.`,
            )
            return
          }

          if (playoffProgression.status === 'complete') {
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
                `${season} playoff run is complete. Advanced to ${nextSeason}.`,
              )
              return
            }

            setCurrentGameType('regular')
            setCurrentGameNumber(REGULAR_SEASON_GAME_COUNT + 1)
            setProgressionMessage(
              `${season} playoff run is complete. No later season is available in the app data.`,
            )
            return
          }

          setCurrentGameType('playoffs')
          setCurrentGameNumber(playoffProgression.nextGameNumber)
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
    reason = `${season} is complete without playoff qualification.`,
  ) => {
    const nextSeason = getNextSeason(season)

    if (!nextSeason) {
      setCurrentGameType('regular')
      setCurrentGameNumber(REGULAR_SEASON_GAME_COUNT + 1)
      setProgressionMessage(
        `${reason} No later season is available in the app data.`,
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
    setProgressionMessage(`${reason} Advanced to ${nextSeason}.`)
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

    if (regularSeasonGames.length >= REGULAR_SEASON_GAME_COUNT) {
      if (checkPlayoffQualification(regularSeasonGames)) {
        const playoffProgression = getPlayoffProgression(
          allGames,
          team,
          season,
        )

        if (playoffProgression.status === 'eliminated') {
          moveToNextSeason(
            allGames,
            team,
            season,
            `${season} playoff run ended in round ${playoffProgression.round}.`,
          )
          return
        }

        if (playoffProgression.status === 'complete') {
          moveToNextSeason(
            allGames,
            team,
            season,
            `${season} playoff run is complete.`,
          )
          return
        }

        setCurrentGameType('playoffs')
        setCurrentGameNumber(playoffProgression.nextGameNumber)
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
    const requestedGames = Array.isArray(games) ? games : [games]
    const gamesToAdd = filterPlayableGames(stats, requestedGames)

    if (gamesToAdd.length === 0) {
      setProgressionMessage(
        'No playoff games were added because the current playoff run is already complete.',
      )
      return
    }

    const newStats = [...stats, ...gamesToAdd]
    saveStats(newStats)

    // Celebrate newly broken NBA records (not ones already achieved before)
    const previouslyBroken = new Set(
      getBrokenRecords(stats).map((comparison) => comparison.record.id),
    )
    const newlyBroken = getBrokenRecords(newStats).filter(
      (comparison) => !previouslyBroken.has(comparison.record.id),
    )
    if (newlyBroken.length > 0) {
      setRecordsCongrats(newlyBroken)
    }

    // Celebrate newly logged games that crack an all-time top-20 leaderboard.
    const entrances = computeTopTwentyEntrances(gamesToAdd)
    if (entrances.length > 0) {
      setTopTwentyCongrats(entrances)
    }

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

    const playoffProgression = getPlayoffProgression(
      stats,
      selectedTeam,
      selectedSeason,
    )

    if (playoffProgression.status === 'eliminated') {
      moveToNextSeason(
        stats,
        selectedTeam,
        selectedSeason,
        `${selectedSeason} playoff run ended in round ${playoffProgression.round}.`,
      )
      return
    }

    if (playoffProgression.status === 'complete') {
      moveToNextSeason(
        stats,
        selectedTeam,
        selectedSeason,
        `${selectedSeason} playoff run is complete.`,
      )
      return
    }

    setCurrentGameType('playoffs')
    setCurrentGameNumber(playoffProgression.nextGameNumber)
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
    if (selectedSeason) {
      setGameProgression(stats, team, selectedSeason)
    } else {
      setCurrentGameNumber(1)
      setCurrentGameType('regular')
      setProgressionMessage('')
    }
  }

  const handleSeasonChange = (targetSeason: string) => {
    if (!targetSeason) {
      setSelectedSeason('')
      return
    }

    if (targetSeason === selectedSeason) {
      if (selectedTeam) {
        setGameProgression(stats, selectedTeam, targetSeason)
      }
      return
    }

    const seasons = getAvailableSeasons()
    const currentIndex = seasons.indexOf(selectedSeason)
    const targetIndex = seasons.indexOf(targetSeason)

    // Warning: switching back to a past season
    if (currentIndex >= 0 && targetIndex >= 0 && targetIndex < currentIndex) {
      const confirmed = window.confirm(
        `Warning: You are switching to a past season (${targetSeason}).\n\nPast seasons are completed and cannot have new games added unless you reset that season to start over.\n\nDo you want to switch to ${targetSeason}?`,
      )
      if (!confirmed) {
        return
      }

      setSelectedSeason(targetSeason)
      if (selectedTeam) {
        setGameProgression(stats, selectedTeam, targetSeason)
      }
      setProgressionMessage(`Switched to past season ${targetSeason}.`)
      return
    }

    // Warning: switching forward to a future season when current season is incomplete
    if (currentIndex >= 0 && targetIndex >= 0 && targetIndex > currentIndex) {
      const currentTeamGames = getTeamSeasonGames(
        stats,
        selectedTeam,
        selectedSeason,
      )
      const regularSeasonGames = currentTeamGames.filter(
        (g) => g.gameType === 'regular',
      )

      if (regularSeasonGames.length < REGULAR_SEASON_GAME_COUNT) {
        const unplayedCount =
          REGULAR_SEASON_GAME_COUNT - regularSeasonGames.length
        const confirmed = window.confirm(
          `Warning: The current season (${selectedSeason}) is not finished (${regularSeasonGames.length}/${REGULAR_SEASON_GAME_COUNT} games played).\n\nSwitching to a future season (${targetSeason}) will forfeit the remaining ${unplayedCount} game(s) as missed games (losses by absence).\n\nDo you want to proceed?`,
        )
        if (!confirmed) {
          return
        }

        const teamId = getTeamId(selectedTeam)
        const schedule = getTeamRegularSeasonSchedule(teamId, selectedSeason)
        const forfeitedGames: GameStats[] = []
        for (
          let i = regularSeasonGames.length;
          i < REGULAR_SEASON_GAME_COUNT;
          i++
        ) {
          const scheduledGame = schedule[i]
          forfeitedGames.push({
            id: `${Date.now()}-${i}-${Math.random().toString(36).slice(2, 7)}`,
            date: scheduledGame?.date || new Date().toISOString().split('T')[0],
            team: selectedTeam,
            opponent: scheduledGame?.opponent || 'Opponent',
            gameNumber: i + 1,
            gameType: 'regular',
            absenceType: 'rest',
            isAbsent: true,
            points: 0,
            assists: 0,
            rebounds: 0,
            blocks: 0,
            steals: 0,
            minutes: 0,
            won: false,
            isDoubleDouble: false,
            isTripleDouble: false,
            isBuzzerBeater: false,
            season: selectedSeason,
          })
        }

        const updatedStats = [...stats, ...forfeitedGames]
        saveStats(updatedStats)
        calculateCareerHighs(updatedStats)
        calculateStatsSummary(updatedStats)
        organizeSeasonStats(updatedStats)

        setSelectedSeason(targetSeason)
        setGameProgression(updatedStats, selectedTeam, targetSeason)
        setProgressionMessage(
          `Forfeited ${unplayedCount} unplayed game(s) in ${selectedSeason}. Advanced to ${targetSeason}.`,
        )
        return
      }
    }

    setSelectedSeason(targetSeason)
    if (selectedTeam) {
      setGameProgression(stats, selectedTeam, targetSeason)
    }
  }

  const handleResetSeason = (seasonToReset: string) => {
    const remainingStats = stats.filter(
      (g) =>
        !(
          g.season === seasonToReset &&
          (!selectedTeam || g.team === selectedTeam)
        ),
    )
    saveStats(remainingStats)
    calculateCareerHighs(remainingStats)
    calculateStatsSummary(remainingStats)
    organizeSeasonStats(remainingStats)

    setCurrentGameType('regular')
    setCurrentGameNumber(1)
    setProgressionMessage(
      `${seasonToReset} season for ${selectedTeam} has been reset. Starting fresh from Game 1.`,
    )
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
          <nav className='app-view-switcher' aria-label='App pages'>
            <button
              type='button'
              onClick={() => setAppView('tracker')}
              className={appView === 'tracker' ? 'active' : ''}
            >
              Tracker
            </button>
            <button
              type='button'
              onClick={() => setAppView('summary')}
              className={appView === 'summary' ? 'active' : ''}
            >
              Summary
            </button>
            <button
              type='button'
              onClick={() => setAppView('records')}
              className={appView === 'records' ? 'active' : ''}
            >
              Records
            </button>
          </nav>
          {appView === 'tracker' && (
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
          )}
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
        {appView === 'tracker' ? (
          <>
            <GameForm
              addGameStats={addGameStats}
              currentGameNumber={currentGameNumber}
              gameType={currentGameType}
              selectedTeam={selectedTeam}
              selectedSeason={selectedSeason}
              onTeamChange={handleTeamChange}
              onSeasonChange={handleSeasonChange}
              onResetSeason={handleResetSeason}
            />
            {progressionMessage && (
              <div className='message info' role='status'>
                {progressionMessage}
              </div>
            )}

            {recordsCongrats.length > 0 && (
              <div className='congrats-banner' role='status'>
                <div className='congrats-banner-list'>
                  {recordsCongrats.map((comparison) => (
                    <p key={comparison.record.id}>
                      🏆 CONGRATULATIONS! You broke the NBA record for{' '}
                      {comparison.record.label} ({comparison.record.holder},{' '}
                      {comparison.record.value} {comparison.record.unit}) with{' '}
                      {comparison.playerValue} {comparison.record.unit}!
                    </p>
                  ))}
                </div>
                <button
                  type='button'
                  className='congrats-dismiss'
                  onClick={() => setRecordsCongrats([])}
                  aria-label='Dismiss congratulations'
                >
                  ✕
                </button>
              </div>
            )}

            {topTwentyCongrats.length > 0 && (
              <div className='congrats-banner' role='status'>
                <div className='congrats-banner-list'>
                  {topTwentyCongrats.map((entrance) => (
                    <p key={`${entrance.boardId}-${entrance.context}`}>
                      🏆 TOP-20 ENTRY! Your {entrance.value}-{entrance.adjective} game ({entrance.context}) ranks #{entrance.rank} all-time for {entrance.boardTitle}!
                    </p>
                  ))}
                </div>
                <button
                  type='button'
                  className='congrats-dismiss'
                  onClick={() => setTopTwentyCongrats([])}
                  aria-label='Dismiss top-20 congratulations'
                >
                  ✕
                </button>
              </div>
            )}

            <StatsDisplay
              stats={stats}
              careerHighs={careerHighs}
              statsSummary={statsSummary}
              seasonStats={seasonStats}
              currentSeason={selectedSeason}
            />

            {selectedSeason && selectedTeam && (
              <ComparisonDisplay
                playerStats={currentSeasonSummary}
                seasonAwards={
                  SEASONS_DATA.find((s) => s.season === selectedSeason)?.awards ||
                  seasonStats.find((s) => s.seasonYear === selectedSeason)
                    ?.seasonAwards ||
                  null
                }
                playerTeam={selectedTeam}
                season={selectedSeason}
                currentRecord={`${currentSeasonSummary.teamWins}-${currentSeasonSummary.teamLosses}`}
              />
            )}
          </>
        ) : appView === 'records' ? (
          <>
            <RecordsDisplay
              stats={stats}
              congrats={recordsCongrats}
              onDismissCongrats={() => setRecordsCongrats([])}
            />
            <AllTimeLeaderboards
              stats={stats}
              playerName={currentUser}
            />
          </>
        ) : (
          <StatsSummaryPage
            stats={stats}
            seasonStats={seasonStats}
            statsSummary={statsSummary}
          />
        )}
      </main>
    </div>
  )
}

export default App
