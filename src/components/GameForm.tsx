import React, { useState } from 'react'
import type { GameStats, AbsenceType, GameType, Team } from '../interfaces'

const NBA_TEAMS: Team[] = [
  { id: 'atl', name: 'Hawks', city: 'Atlanta' },
  { id: 'bos', name: 'Celtics', city: 'Boston' },
  { id: 'bkn', name: 'Nets', city: 'Brooklyn' },
  { id: 'cha', name: 'Hornets', city: 'Charlotte' },
  { id: 'chi', name: 'Bulls', city: 'Chicago' },
  { id: 'cle', name: 'Cavaliers', city: 'Cleveland' },
  { id: 'dal', name: 'Mavericks', city: 'Dallas' },
  { id: 'den', name: 'Nuggets', city: 'Denver' },
  { id: 'det', name: 'Pistons', city: 'Detroit' },
  { id: 'gsw', name: 'Warriors', city: 'Golden State' },
  { id: 'hou', name: 'Rockets', city: 'Houston' },
  { id: 'ind', name: 'Pacers', city: 'Indiana' },
  { id: 'lac', name: 'Clippers', city: 'LA' },
  { id: 'lal', name: 'Lakers', city: 'LA' },
  { id: 'mem', name: 'Grizzlies', city: 'Memphis' },
  { id: 'mia', name: 'Heat', city: 'Miami' },
  { id: 'mil', name: 'Bucks', city: 'Milwaukee' },
  { id: 'min', name: 'Timberwolves', city: 'Minnesota' },
  { id: 'nop', name: 'Pelicans', city: 'New Orleans' },
  { id: 'nyk', name: 'Knicks', city: 'New York' },
  { id: 'okc', name: 'Thunder', city: 'Oklahoma City' },
  { id: 'orl', name: 'Magic', city: 'Orlando' },
  { id: 'phi', name: '76ers', city: 'Philadelphia' },
  { id: 'phx', name: 'Suns', city: 'Phoenix' },
  { id: 'por', name: 'Trail Blazers', city: 'Portland' },
  { id: 'sac', name: 'Kings', city: 'Sacramento' },
  { id: 'sas', name: 'Spurs', city: 'San Antonio' },
  { id: 'tor', name: 'Raptors', city: 'Toronto' },
  { id: 'uta', name: 'Jazz', city: 'Utah' },
  { id: 'was', name: 'Wizards', city: 'Washington' }
]

const GameForm: React.FC<{ addGameStats: (game: GameStats) => void; currentGameNumber: number; gameType: GameType }> = ({ 
  addGameStats, 
  currentGameNumber, 
  gameType 
}) => {
  const [game, setGame] = useState<GameStats>({
    id: Date.now().toString(),
    date: new Date().toISOString().split('T')[0],
    team: '',
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
  })

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
      alert('Please enter an opponent')
      return
    }
    addGameStats(game)
    setGame({
      id: Date.now().toString(),
      date: new Date().toISOString().split('T')[0],
      team: game.team,
      opponent: '',
      gameNumber: currentGameNumber + 1,
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
    })
  }

  return (
    <div className='GameForm'>
      <h2>Enter Game Stats - {gameType === 'regular' ? 'Regular Season' : 'Playoffs'} Game {currentGameNumber}</h2>
      <form
        onSubmit={(e) => {
          e.preventDefault()
          submitGame()
        }}
      >
        <div className="form-row">
          <div>
            <label htmlFor='date'>Date</label>
            <input
              type='date'
              value={game.date}
              onChange={(e) => updateStats({ date: e.target.value })}
              id='date'
            />
          </div>
          <div>
            <label htmlFor='team'>Team</label>
            <select
              value={game.team}
              onChange={(e) => updateStats({ team: e.target.value })}
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
          <div>
            <label htmlFor='opponent'>Opponent</label>
            <input
              type='text'
              placeholder='Opponent Team'
              value={game.opponent}
              onChange={(e) => updateStats({ opponent: e.target.value })}
              id='opponent'
              required
            />
          </div>
        </div>

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

        <button type='submit'>Submit Game</button>
      </form>
    </div>
  )
}

export default GameForm
