import React, { useState, useEffect } from 'react'
import type { GameStats, AbsenceType, GameType, Team } from '../interfaces'
import { NBA_TEAMS, getTeamSchedule, getAvailableSeasons } from '../data/nbaData'

const GameForm: React.FC<{ 
  addGameStats: (game: GameStats) => void
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

  const [currentSchedule, setCurrentSchedule] = useState<any[]>([])

  useEffect(() => {
    if (selectedTeam && selectedSeason) {
      const schedule = getTeamSchedule(
        NBA_TEAMS.find(t => `${t.city} ${t.name}` === selectedTeam)?.id || '',
        selectedSeason
      )
      setCurrentSchedule(schedule)
      
      // Set current game date and opponent based on schedule
      const currentGameIndex = currentGameNumber - 1
      if (schedule[currentGameIndex]) {
        const currentScheduledGame = schedule[currentGameIndex]
        setGame(prev => ({
          ...prev,
          date: currentScheduledGame.date,
          opponent: currentScheduledGame.opponent,
          team: selectedTeam,
          season: selectedSeason,
          gameType: currentScheduledGame.isPlayoff ? 'playoffs' : 'regular'
        }))
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
  }

  const submitGame = () => {
    if (!game.team) {
      alert('Please select a team')
      return
    }
    if (!game.opponent) {
      alert('No opponent scheduled for this game')
      return
    }
    addGameStats(game)
  }

  const availableSeasons = getAvailableSeasons()

  return (
    <div className='GameForm'>
      <h2>Enter Game Stats - {gameType === 'regular' ? 'Regular Season' : 'Playoffs'} Game {currentGameNumber}</h2>
      
      {/* Season and Team Selection */}
      <div className="form-row">
        <div>
          <label htmlFor='season'>Season</label>
          <select
            value={selectedSeason}
            onChange={(e) => onSeasonChange(e.target.value)}
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
            onChange={(e) => onTeamChange(e.target.value)}
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
      {selectedTeam && selectedSeason && (
        <div className="game-info">
          <h3>Current Game</h3>
          <p><strong>Date:</strong> {game.date}</p>
          <p><strong>Opponent:</strong> {game.opponent}</p>
          <p><strong>Game Type:</strong> {gameType === 'regular' ? 'Regular Season' : 'Playoffs'}</p>
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
            <label htmlFor='absenceType'>Absence Status</label>
            <select
              value={game.absenceType}
              onChange={(e) => {
                const absenceType = e.target.value as AbsenceType
                const isAbsent = absenceType !== 'none'
                updateStats({ absenceType, isAbsent })
              }}
              id='absenceType'
            >
              <option value='none'>Playing</option>
              <option value='rest'>Rest</option>
              <option value='injury'>Injury</option>
              <option value='personal'>Personal</option>
              <option value='suspension'>Suspension</option>
            </select>
          </div>
        </div>

        {!game.isAbsent && (
          <>
            <div className="form-row">
              <div>
                <label htmlFor='minutes'>Minutes</label>
                <input
                  type='number'
                  placeholder='Minutes'
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
                  placeholder='Points'
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
                  placeholder='Assists'
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
                  placeholder='Rebounds'
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
                  placeholder='Blocks'
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
                  placeholder='Steals'
                  value={game.steals || ''}
                  onChange={(e) => updateStats({ steals: +e.target.value })}
                  id='steals'
                  min={0}
                />
              </div>
            </div>

            <div className="form-row">
              <div>
                <label>
                  <input 
                    type='checkbox' 
                    checked={game.won} 
                    onChange={(e) => updateStats({ won: e.target.checked })} 
                  />
                  Won Game
                </label>
              </div>
              <div>
                <p>Double-Double: {game.isDoubleDouble ? 'Yes' : 'No'}</p>
              </div>
              <div>
                <p>Triple-Double: {game.isTripleDouble ? 'Yes' : 'No'}</p>
              </div>
            </div>
          </>
        )}

        {game.isAbsent && (
          <div className="absence-notice">
            <p>Player is absent ({game.absenceType}). No statistics will be recorded.</p>
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

        <button type='submit' disabled={!selectedTeam || !selectedSeason || !game.opponent}>
          Submit Game
        </button>
      </form>
    </div>
  )
}

export default GameForm
