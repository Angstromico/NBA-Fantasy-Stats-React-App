import React, { useState, useEffect } from 'react'
import type { GameStats, AbsenceType, GameType } from '../interfaces'
import { NBA_TEAMS, getTeamSchedule, getAvailableSeasons } from '../data/nbaData'

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
    season: selectedSeason
  })

  const [skipMode, setSkipMode] = useState(false)
  const [skipCount, setSkipCount] = useState(1)
  const [skipToSeasonEnd, setSkipToSeasonEnd] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    if (selectedTeam && selectedSeason) {
      const schedule = getTeamSchedule(
        NBA_TEAMS.find(t => `${t.city} ${t.name}` === selectedTeam)?.id || '',
        selectedSeason
      )
      
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
          gameType: currentScheduledGame.isPlayoff ? 'playoffs' : 'regular',
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
        })
      }
    }
  }, [selectedTeam, selectedSeason, currentGameNumber])

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
    if (!newGame.isAbsent) {
      newGame.isDoubleDouble = calculateDoubleDouble(newGame)
      newGame.isTripleDouble = calculateTripleDouble(newGame)
    } else {
      newGame.isDoubleDouble = false
      newGame.isTripleDouble = false
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
      const schedule = getTeamSchedule(
        NBA_TEAMS.find(t => `${t.city} ${t.name}` === selectedTeam)?.id || '',
        selectedSeason
      )

      let gamesToSkip = skipCount
      if (skipToSeasonEnd) {
        gamesToSkip = schedule.length - (currentGameNumber - 1)
      }

      const bulkGames: GameStats[] = []
      for (let i = 0; i < gamesToSkip; i++) {
        const index = (currentGameNumber - 1) + i
        if (schedule[index]) {
          const scheduledGame = schedule[index]
          bulkGames.push({
            ...game,
            id: crypto.randomUUID(),
            date: scheduledGame.date,
            opponent: scheduledGame.opponent,
            gameNumber: currentGameNumber + i,
            gameType: scheduledGame.isPlayoff ? 'playoffs' : 'regular',
            isAbsent: true,
            // Stats are already 0'd by updateStats when absenceType is set
          })
        }
      }

      if (bulkGames.length === 0) {
        setError('No games found to skip')
        return
      }

      addGameStats(bulkGames)
      setSkipMode(false)
      setSkipCount(1)
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
                  onChange={(e) => setSkipCount(Math.max(1, +e.target.value))}
                  disabled={skipToSeasonEnd}
                  id='skipCount'
                  min={1}
                />
                <label className="checkbox-label">
                  <input 
                    type="checkbox" 
                    checked={skipToSeasonEnd} 
                    onChange={(e) => setSkipToSeasonEnd(e.target.checked)} 
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
                <input
                  type='number'
                  placeholder='0'
                  value={game.minutes || ''}
                  onChange={(e) => updateStats({ minutes: +e.target.value })}
                  id='minutes'
                  min={0}
                  max={48}
                />
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
                  />
                  Team Won Game
                </label>
              </div>
              <div className={`badge ${game.isDoubleDouble ? 'active' : ''}`}>
                Double-Double
              </div>
              <div className={`badge ${game.isTripleDouble ? 'active' : ''}`}>
                Triple-Double
              </div>
            </div>
          </>
        )}

        {(game.isAbsent || skipMode) && (
          <div className="absence-notice">
            <p>
              {skipMode 
                ? `Player will be marked as absent for ${skipToSeasonEnd ? 'the rest of the season' : `${skipCount} game(s)`} due to ${game.absenceType.replace(/_/g, ' ')}.`
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
               <p className="hint">Note: Team wins for skipped games will be recorded as losses by default in this mode.</p>
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
