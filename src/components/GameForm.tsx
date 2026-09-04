import React, { useState, useEffect, useMemo } from 'react'
import type { GameStats, AbsenceType, GameType } from '../interfaces'
import {
  NBA_TEAMS,
  getAvailableSeasons,
  getNextSeason,
  getTeamPlayoffSchedule,
  getTeamRegularSeasonSchedule,
} from '../data/nbaData'

const GameForm: React.FC<{ 
  addGameStats: (games: GameStats | GameStats[]) => void
  currentGameNumber: number
  gameType: GameType
  selectedTeam: string
  selectedSeason: string
  onTeamChange: (team: string) => void
  onSeasonChange: (season: string) => void
}> = ({ 
  addGameStats, 
  currentGameNumber, 
  gameType,
  selectedTeam,
  selectedSeason,
  onTeamChange,
  onSeasonChange
}) => {
  const [game, setGame] = useState<GameStats>({
    id: Date.now().toString(),
    date: new Date().toISOString().split('T')[0],
    team: selectedTeam,
    opponent: '',
    gameNumber: currentGameNumber,
    gameType,
    absenceType: 'none',
    isAbsent: false,
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
    season: selectedSeason
  })

  const [skipMode, setSkipMode] = useState(false)
  const [skipCount, setSkipCount] = useState(1)
  const [skipWins, setSkipWins] = useState(1)
  const [skipToSeasonEnd, setSkipToSeasonEnd] = useState(false)
  const [error, setError] = useState('')

  const selectedTeamId = useMemo(
    () => NBA_TEAMS.find(
      t => `${t.city} ${t.name}` === selectedTeam,
    )?.id || '',
    [selectedTeam],
  )
  const schedule = useMemo(
    () => (
      gameType === 'playoffs'
        ? getTeamPlayoffSchedule(selectedTeamId, selectedSeason)
        : getTeamRegularSeasonSchedule(selectedTeamId, selectedSeason)
    ),
    [gameType, selectedSeason, selectedTeamId],
  )
  const remainingGames = Math.max(0, schedule.length - (currentGameNumber - 1))
  const totalRegularGamesAvailable = useMemo(() => {
    if (!selectedTeamId || !selectedSeason) {
      return 0
    }

    let season: string | null = selectedSeason
    let gameNumber = currentGameNumber
    let availableGames = 0

    while (season) {
      const seasonSchedule = getTeamRegularSeasonSchedule(selectedTeamId, season)
      availableGames += Math.max(0, seasonSchedule.length - (gameNumber - 1))
      season = getNextSeason(season)
      gameNumber = 1
    }

    return availableGames
  }, [currentGameNumber, selectedSeason, selectedTeamId])
  const availableSkipGames = gameType === 'regular'
    ? totalRegularGamesAvailable
    : remainingGames
  const gamesInInterval = Math.min(
    skipToSeasonEnd ? remainingGames : skipCount,
    availableSkipGames,
  )
  const intervalWins = Math.min(skipWins, gamesInInterval)
  const intervalLosses = gamesInInterval - intervalWins
  const intervalWinPercentage = gamesInInterval
    ? Math.round((intervalWins / gamesInInterval) * 100)
    : 0
  const recordTone = intervalWinPercentage >= 75
    ? 'is-dominant'
    : intervalWinPercentage >= 55
      ? 'is-ahead'
      : intervalWinPercentage >= 45
        ? 'is-even'
        : intervalWinPercentage >= 25
          ? 'is-behind'
          : 'is-struggling'
  const recordSummary = intervalWinPercentage >= 75
    ? 'Dominating the interval'
    : intervalWinPercentage >= 55
      ? 'Winning interval'
      : intervalWinPercentage >= 45
        ? 'Even interval'
        : intervalWinPercentage >= 25
          ? 'Tough stretch'
          : 'Reset mode'
  const recordSymbol = intervalWinPercentage >= 75
    ? 'W'
    : intervalWinPercentage >= 45
      ? '='
      : 'L'
  const recordBarStyle = {
    '--win-share': `${intervalWinPercentage}%`,
  } as React.CSSProperties
  const minutesPlayed = Number(game.minutes) || 0
  const overtimeMinutes = Math.max(0, minutesPlayed - 48)
  const overtimeWarning = minutesPlayed > 48
    ? overtimeMinutes >= 12
      ? `Marathon territory. This is ${minutesPlayed} minutes, or ${overtimeMinutes} minutes beyond regulation.`
      : `Overtime territory. This is ${minutesPlayed} minutes, which is ${overtimeMinutes} minute${overtimeMinutes === 1 ? '' : 's'} beyond regulation.`
    : ''
  const minutesHint = 'NBA regulation is 48 minutes. Overtime is allowed, so the field stays open.'

  const setBalancedRecord = (gameCount: number) => {
    setSkipWins(Math.ceil(gameCount / 2))
  }

  const updateSkipCount = (value: string) => {
    const requestedCount = Number(value)
    const nextCount = Math.min(
      availableSkipGames || 1,
      Math.max(1, Number.isFinite(requestedCount) ? requestedCount : 1),
    )
    setSkipCount(nextCount)
    setBalancedRecord(nextCount)
  }

  const buildRandomOutcomes = (totalGames: number, wins: number): boolean[] => {
    // Shuffle the exact win/loss counts so the order feels organic instead of a fixed spread.
    const outcomes = Array.from({ length: totalGames }, (_, index) => index < wins)
    for (let i = outcomes.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1))
      const swap = outcomes[i]
      outcomes[i] = outcomes[j]
      outcomes[j] = swap
    }
    return outcomes
  }

  const buildSkippedRegularSeasonGames = (totalGames: number): GameStats[] => {
    const skippedGames: GameStats[] = []
    const outcomes = buildRandomOutcomes(totalGames, intervalWins)
    let season: string | null = selectedSeason
    let gameNumber = currentGameNumber

    while (season && skippedGames.length < totalGames) {
      const seasonSchedule = getTeamRegularSeasonSchedule(selectedTeamId, season)

      for (
        let index = gameNumber - 1;
        index < seasonSchedule.length && skippedGames.length < totalGames;
        index++
      ) {
        const scheduledGame = seasonSchedule[index]
        const intervalIndex = skippedGames.length

        skippedGames.push({
          ...game,
          id: crypto.randomUUID(),
          date: scheduledGame.date,
          opponent: scheduledGame.opponent,
          gameNumber: index + 1,
          gameType: 'regular',
          season,
          isAbsent: true,
          won: outcomes[intervalIndex],
        })
      }

      season = getNextSeason(season)
      gameNumber = 1
    }

    return skippedGames
  }

  const buildSkippedPlayoffGames = (totalGames: number): GameStats[] => {
    const skippedGames: GameStats[] = []
    const outcomes = buildRandomOutcomes(totalGames, intervalWins)

    for (let i = 0; i < totalGames; i++) {
      const index = (currentGameNumber - 1) + i
      const scheduledGame = schedule[index]

      if (scheduledGame) {
        skippedGames.push({
          ...game,
          id: crypto.randomUUID(),
          date: scheduledGame.date,
          opponent: scheduledGame.opponent,
          gameNumber: currentGameNumber + i,
          gameType: 'playoffs',
          season: selectedSeason,
          isAbsent: true,
          won: outcomes[i],
        })
      }
    }

    return skippedGames
  }

  useEffect(() => {
    if (selectedTeam && selectedSeason) {
      // Set current game date and opponent based on schedule
      const currentGameIndex = currentGameNumber - 1
      if (schedule[currentGameIndex]) {
        const currentScheduledGame = schedule[currentGameIndex]
        setGame({
          id: crypto.randomUUID(),
          date: currentScheduledGame.date,
          opponent: currentScheduledGame.opponent,
          team: selectedTeam,
          season: selectedSeason,
          gameType,
          gameNumber: currentGameNumber,
          absenceType: 'none',
          isAbsent: false,
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
        })
      } else {
        setGame(currentGame => ({
          ...currentGame,
          id: crypto.randomUUID(),
          date: new Date().toISOString().split('T')[0],
          opponent: '',
          team: selectedTeam,
          season: selectedSeason,
          gameType,
          gameNumber: currentGameNumber,
          isBuzzerBeater: false,
        }))
      }
    }
  }, [selectedTeam, selectedSeason, currentGameNumber, gameType, schedule])

  const calculateDoubleDouble = (stats: GameStats): boolean => {
    const categories = [stats.points, stats.assists, stats.rebounds, stats.blocks, stats.steals]
    return categories.filter(cat => cat >= 10).length >= 2
  }

  const calculateTripleDouble = (stats: GameStats): boolean => {
    const categories = [stats.points, stats.assists, stats.rebounds, stats.blocks, stats.steals]
    return categories.filter(cat => cat >= 10).length >= 3
  }

  const updateStats = (updates: Partial<GameStats>) => {
    const newGame = { ...game, ...updates }
    // A buzzer beater can only end in a win — lock the result in so the
    // game can never be recorded as a loss while the toggle is on.
    if (newGame.isBuzzerBeater) {
      newGame.won = true
    }
    if (!newGame.isAbsent) {
      newGame.isDoubleDouble = calculateDoubleDouble(newGame)
      newGame.isTripleDouble = calculateTripleDouble(newGame)
    } else {
      newGame.isDoubleDouble = false
      newGame.isTripleDouble = false
      newGame.isBuzzerBeater = false
      newGame.points = 0
      newGame.assists = 0
      newGame.rebounds = 0
      newGame.blocks = 0
      newGame.steals = 0
      newGame.minutes = 0
    }
    setGame(newGame)
    setError('')
  }

  const submitGame = () => {
    if (!game.team) {
      setError('Please select a team')
      return
    }

    if (skipMode) {
      const bulkGames = gameType === 'regular'
        ? buildSkippedRegularSeasonGames(gamesInInterval)
        : buildSkippedPlayoffGames(gamesInInterval)

      if (bulkGames.length === 0) {
        setError('No games found to skip')
        return
      }

      addGameStats(bulkGames)
      setSkipMode(false)
      setSkipCount(1)
      setSkipWins(1)
      setSkipToSeasonEnd(false)
    } else {
      if (!game.opponent) {
        setError('No opponent scheduled for this game')
        return
      }
      addGameStats(game)
    }
    setError('')
  }

  const availableSeasons = getAvailableSeasons()

  return (
    <div className='GameForm glass-card'>
      <div className="form-header">
        <h2>{gameType === 'regular' ? 'Regular Season' : 'Playoffs'} Game {currentGameNumber}</h2>
        <div className="skip-toggle">
          <label className="switch">
            <input 
              type="checkbox" 
              checked={skipMode} 
              onChange={(e) => {
                setSkipMode(e.target.checked)
                if (e.target.checked && game.absenceType === 'none') {
                  updateStats({ absenceType: 'rest', isAbsent: true })
                }
                if (e.target.checked) {
                  setBalancedRecord(skipToSeasonEnd ? remainingGames : skipCount)
                }
              }} 
            />
            <span className="slider round"></span>
          </label>
          <span>Bulk Skip Mode</span>
        </div>
      </div>
      
      {error && <div className='message error' role='alert'>{error}</div>}

      {/* Season and Team Selection */}
      <div className="form-row">
        <div>
          <label htmlFor='season'>Season</label>
          <select
            value={selectedSeason}
            onChange={(e) => {
              onSeasonChange(e.target.value)
              setError('')
            }}
            id='season'
            required
          >
            <option value=''>Select Season</option>
            {availableSeasons.map(season => (
              <option key={season} value={season}>
                {season}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label htmlFor='team'>Team</label>
          <select
            value={selectedTeam}
            onChange={(e) => {
              onTeamChange(e.target.value)
              setError('')
            }}
            id='team'
            required
          >
            <option value=''>Select Team</option>
            {NBA_TEAMS.map(team => (
              <option key={team.id} value={`${team.city} ${team.name}`}>
                {team.city} {team.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Current Game Info */}
      {!skipMode && selectedTeam && selectedSeason && (
        <div className="game-info glass-card">
          <h3>Upcoming Matchup</h3>
          <div className="game-info-grid">
            <p><span>Date</span> <strong>{game.date}</strong></p>
            <p><span>Opponent</span> <strong>{game.opponent}</strong></p>
            <p><span>Format</span> <strong>{gameType === 'regular' ? 'Regular Season' : 'Playoffs'}</strong></p>
          </div>
        </div>
      )}

      <form
        onSubmit={(e) => {
          e.preventDefault()
          submitGame()
        }}
      >
        <div className="form-row">
          <div>
            <label htmlFor='absenceType'>Absence Reason</label>
            <select
              value={game.absenceType}
              onChange={(e) => {
                const absenceType = e.target.value as AbsenceType
                const isAbsent = absenceType !== 'none'
                updateStats({ absenceType, isAbsent })
                if (!isAbsent) setSkipMode(false)
              }}
              id='absenceType'
            >
              <option value='none'>Active</option>
              <option value='rest'>Rest</option>
              <option value='injury'>Injury</option>
              <option value='personal'>Personal</option>
              <option value='suspension'>Suspension</option>
              <option value='not_called_up'>Not Called Up</option>
              <option value='lower_division'>Lower Division</option>
              <option value='lesson'>Lesson</option>
            </select>
          </div>
          {skipMode && (
             <div>
              <label htmlFor='skipCount'>Number of Games</label>
              <div className="skip-input-group">
                <input
                  type='number'
                  value={skipCount}
                  onChange={(e) => updateSkipCount(e.target.value)}
                  disabled={skipToSeasonEnd}
                  id='skipCount'
                  min={1}
                  max={availableSkipGames || 1}
                />
                <label className="checkbox-label">
                  <input 
                    type="checkbox" 
                    checked={skipToSeasonEnd} 
                    onChange={(e) => {
                      setSkipToSeasonEnd(e.target.checked)
                      setBalancedRecord(e.target.checked ? remainingGames : skipCount)
                    }}
                  />
                  Until Season End
                </label>
              </div>
           </div>
          )}
        </div>

        {!game.isAbsent && !skipMode && (
          <>
            <div className="form-row">
              <div>
                <label htmlFor='minutes'>Minutes</label>
                <div className={`minutes-input-wrap ${minutesPlayed > 48 ? 'overtime' : ''}`}>
                  <input
                    type='number'
                    placeholder='0'
                    value={game.minutes || ''}
                    onChange={(e) => updateStats({ minutes: +e.target.value })}
                    id='minutes'
                    step={1}
                    inputMode='numeric'
                    min={0}
                  />
                  <p className='hint minutes-hint'>{minutesHint}</p>
                  {minutesPlayed > 48 && (
                    <p className='minutes-warning show' aria-live='polite'>
                      {overtimeWarning}
                    </p>
                  )}
                </div>
              </div>
              <div>
                <label htmlFor='points'>Points</label>
                <input
                  type='number'
                  placeholder='0'
                  value={game.points || ''}
                  onChange={(e) => updateStats({ points: +e.target.value })}
                  id='points'
                  min={0}
                />
              </div>
              <div>
                <label htmlFor='assists'>Assists</label>
                <input
                  type='number'
                  placeholder='0'
                  value={game.assists || ''}
                  onChange={(e) => updateStats({ assists: +e.target.value })}
                  id='assists'
                  min={0}
                />
              </div>
            </div>

            <div className="form-row">
              <div>
                <label htmlFor='rebounds'>Rebounds</label>
                <input
                  type='number'
                  placeholder='0'
                  value={game.rebounds || ''}
                  onChange={(e) => updateStats({ rebounds: +e.target.value })}
                  id='rebounds'
                  min={0}
                />
              </div>
              <div>
                <label htmlFor='blocks'>Blocks</label>
                <input
                  type='number'
                  placeholder='0'
                  value={game.blocks || ''}
                  onChange={(e) => updateStats({ blocks: +e.target.value })}
                  id='blocks'
                  min={0}
                />
              </div>
              <div>
                <label htmlFor='steals'>Steals</label>
                <input
                  type='number'
                  placeholder='0'
                  value={game.steals || ''}
                  onChange={(e) => updateStats({ steals: +e.target.value })}
                  id='steals'
                  min={0}
                />
              </div>
            </div>

            <div className="form-row status-row">
              <div className="checkbox-group">
                <label>
                  <input 
                    type='checkbox' 
                    checked={game.won} 
                    onChange={(e) => updateStats({ won: e.target.checked })} 
                    disabled={game.isBuzzerBeater}
                    title={game.isBuzzerBeater ? 'A buzzer beater always ends in a win' : undefined}
                  />
                  Team Won Game
                </label>
                {game.isBuzzerBeater && (
                  <p className="buzzer-beater-note">
                    🔥 Buzzer beaters always end in a win — result locked
                  </p>
                )}
              </div>
              <div className={`badge ${game.isDoubleDouble ? 'active' : ''}`}>
                Double-Double
              </div>
              <div className={`badge ${game.isTripleDouble ? 'active' : ''}`}>
                Triple-Double
              </div>
              <div className={`buzzer-beater-toggle${game.isBuzzerBeater ? ' active' : ''}`}>
                <label className="switch buzzer-beater-switch">
                  <input
                    type="checkbox"
                    checked={game.isBuzzerBeater}
                    onChange={(e) => updateStats({ isBuzzerBeater: e.target.checked })}
                    aria-label="Mark this game as a buzzer beater"
                  />
                  <span className="slider round"></span>
                </label>
                <span className="buzzer-beater-label">
                  <span className="buzzer-beater-flame-icon" aria-hidden="true">🔥</span>
                  Buzzer Beater
                </span>
                {game.isBuzzerBeater && (
                  <span className="buzzer-beater-flames" aria-hidden="true">
                    <span className="flame flame-1" />
                    <span className="flame flame-2" />
                    <span className="flame flame-3" />
                  </span>
                )}
              </div>
            </div>
          </>
        )}

        {(game.isAbsent || skipMode) && (
          <div className="absence-notice">
            <p>
              {skipMode 
                ? `Player will be marked as absent for ${skipToSeasonEnd ? 'the rest of the season' : `${gamesInInterval} game(s)`} due to ${game.absenceType.replace(/_/g, ' ')}.`
                : `Player is absent (${game.absenceType.replace(/_/g, ' ')}). No statistics will be recorded.`
              }
            </p>
            {!skipMode && (
              <div className="checkbox-group">
                <label>
                  <input 
                    type='checkbox' 
                    checked={game.won} 
                    onChange={(e) => updateStats({ won: e.target.checked })} 
                  />
                  Team Won Game
                </label>
              </div>
            )}
            {skipMode && (
              <section className={`bulk-record-panel ${recordTone}`} aria-live="polite">
                <div className="bulk-record-heading">
                  <div>
                    <span className="eyebrow">Projected team record</span>
                    <h3>{intervalWins}-{intervalLosses}</h3>
                    <p>{recordSummary}</p>
                  </div>
                  <div className="record-orbit" aria-hidden="true">
                    <span>{recordSymbol}</span>
                  </div>
                </div>

                <div className="record-meter" style={recordBarStyle}>
                  <div className="record-meter-wins" />
                  <div className="record-meter-losses" />
                </div>
                <div className="record-meter-labels" aria-hidden="true">
                  <span>{intervalWins} wins</span>
                  <strong>{intervalWinPercentage}%</strong>
                  <span>{intervalLosses} losses</span>
                </div>

                <div className="record-selector">
                  <label htmlFor="skipWins">Wins in this interval</label>
                  <div className="record-inputs">
                    <input
                      type="range"
                      id="skipWins"
                      min={0}
                      max={gamesInInterval}
                      value={intervalWins}
                      onChange={(e) => setSkipWins(Number(e.target.value))}
                      aria-describedby="skipWinsHelp"
                    />
                    <input
                      type="number"
                      min={0}
                      max={gamesInInterval}
                      value={intervalWins}
                      onChange={(e) => setSkipWins(Math.min(
                        gamesInInterval,
                        Math.max(0, Number(e.target.value) || 0),
                      ))}
                      aria-label="Number of wins in this interval"
                    />
                  </div>
                  <p id="skipWinsHelp">Losses update automatically. Win and loss order is randomized across the skipped games.</p>
                </div>
              </section>
            )}
          </div>
        )}

        <button type='submit' className='primary-btn' disabled={!selectedTeam || !selectedSeason || (!skipMode && !game.opponent)}>
          {skipMode ? 'Confirm Bulk Skip' : 'Submit Stats'}
        </button>
      </form>
    </div>
  )
}

export default GameForm
