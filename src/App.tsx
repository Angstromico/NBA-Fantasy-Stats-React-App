// MVP Race Fantasy NBA Player App

import React, { useState, useEffect } from 'react'
import type { User, GameStats, CareerHighs, StatsSummary } from './interfaces'
import './App.css'

const App: React.FC = () => {
  const [users, setUsers] = useState<User[]>([])
  const [currentUser, setCurrentUser] = useState<string | null>(null)
  const [stats, setStats] = useState<GameStats[]>([])
  const [careerHighs, setCareerHighs] = useState<CareerHighs | null>(null)
  const [statsSummary, setStatsSummary] = useState<StatsSummary | null>(null)

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
      setStats(JSON.parse(savedStats))
    }
  }, [])

  useEffect(() => {
    if (stats.length) {
      calculateCareerHighs(stats)
      calculateStatsSummary(stats)
    }
  }, [stats])

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
    calculateCareerHighs(newStats)
  }

  const calculateCareerHighs = (games: GameStats[]) => {
    const highs: CareerHighs = {
      points: Math.max(...games.map((g) => g.points), 0),
      assists: Math.max(...games.map((g) => g.assists), 0),
      rebounds: Math.max(...games.map((g) => g.rebounds), 0),
      blocks: Math.max(...games.map((g) => g.blocks), 0),
      steals: Math.max(...games.map((g) => g.steals), 0),
    }
    setCareerHighs(highs)
  }

  if (!currentUser) {
    return <Login users={users} login={login} saveUsers={saveUsers} />
  }

  const calculateStatsSummary = (games: GameStats[]) => {
    const totalGames = games.length
    const wins = games.filter((g) => g.won).length
    const losses = totalGames - wins

    const averages = {
      points: games.reduce((sum, g) => sum + g.points, 0) / totalGames,
      assists: games.reduce((sum, g) => sum + g.assists, 0) / totalGames,
      rebounds: games.reduce((sum, g) => sum + g.rebounds, 0) / totalGames,
      blocks: games.reduce((sum, g) => sum + g.blocks, 0) / totalGames,
      steals: games.reduce((sum, g) => sum + g.steals, 0) / totalGames,
    }

    setStatsSummary({ wins, losses, averages })
  }

  return (
    <div className='App'>
      <header>
        <h1>MVP Race Fantasy NBA Player</h1>
        <button onClick={logout}>Logout</button>
      </header>
      <GameForm addGameStats={addGameStats} />
      <StatsDisplay stats={stats} careerHighs={careerHighs} statsSummary={statsSummary} />
    </div>
  )
}

const Login: React.FC<{
  users: User[]
  login: (username: string, password: string) => void
  saveUsers: (users: User[]) => void
}> = ({ users, login, saveUsers }) => {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')

  const register = () => {
    if (!username.trim() || !password.trim()) {
      alert('Username and password cannot be empty.')
      return
    }

    if (!users.some((u) => u.username === username)) {
      const newUsers = [...users, { username, password }]
      saveUsers(newUsers)
      alert('Registration successful!')
    } else {
      alert('Username already exists.')
    }
  }

  return (
    <div className='Login'>
      <h2>Login</h2>
      <form
        onSubmit={(e) => {
          e.preventDefault()
          login(username, password)
        }}
      >
        <input type='text' placeholder='Username' value={username} onChange={(e) => setUsername(e.target.value)} />
        <input type='password' placeholder='Password' value={password} onChange={(e) => setPassword(e.target.value)} />
        <button type='submit'>Login</button>
        <button type='button' onClick={register}>
          Register
        </button>
      </form>
    </div>
  )
}

const GameForm: React.FC<{ addGameStats: (game: GameStats) => void }> = ({ addGameStats }) => {
  const [game, setGame] = useState<GameStats>({
    points: 0,
    assists: 0,
    rebounds: 0,
    blocks: 0,
    steals: 0,
    won: false,
  })

  const submitGame = () => {
    addGameStats(game)
    setGame({ points: 0, assists: 0, rebounds: 0, blocks: 0, steals: 0, won: false })
  }

  return (
    <div className='GameForm'>
      <h2>Enter Game Stats</h2>
      <form
        onSubmit={(e) => {
          e.preventDefault()
          submitGame()
        }}
      >
        <label htmlFor='points'>Points</label>
        <input
          type='number'
          placeholder='Points'
          value={game.points || ''}
          onChange={(e) => setGame({ ...game, points: +e.target.value })}
          id='points'
        />
        <label htmlFor='assists'>Assist</label>
        <input
          type='number'
          placeholder='Assists'
          value={game.assists || ''}
          onChange={(e) => setGame({ ...game, assists: +e.target.value })}
          id='assists'
          min={0}
        />
        <label htmlFor='rebounts'>Rebounts</label>
        <input
          type='number'
          placeholder='Rebounds'
          value={game.rebounds || ''}
          onChange={(e) => setGame({ ...game, rebounds: +e.target.value })}
          id='rebounts'
          min={0}
        />
        <label htmlFor='blocks'>Blocks</label>
        <input
          type='number'
          placeholder='Blocks'
          value={game.blocks || ''}
          onChange={(e) => setGame({ ...game, blocks: +e.target.value })}
          id='blocks'
          min={0}
        />
        <label htmlFor='steals'>Steals</label>
        <input
          type='number'
          placeholder='Steals'
          value={game.steals || ''}
          onChange={(e) => setGame({ ...game, steals: +e.target.value })}
          id='steals'
          min={0}
        />
        <label>
          <input type='checkbox' checked={game.won} onChange={(e) => setGame({ ...game, won: e.target.checked })} />
          Won Game
        </label>
        <button type='submit'>Submit Game</button>
      </form>
    </div>
  )
}

const StatsDisplay: React.FC<{
  stats: GameStats[]
  careerHighs: CareerHighs | null
  statsSummary: StatsSummary | null
}> = ({ stats, careerHighs, statsSummary }) => {
  const [showAll, setShowAll] = useState(false)

  const totals = stats.reduce(
    (acc, game) => ({
      points: acc.points + game.points,
      assists: acc.assists + game.assists,
      rebounds: acc.rebounds + game.rebounds,
      blocks: acc.blocks + game.blocks,
      steals: acc.steals + game.steals,
    }),
    { points: 0, assists: 0, rebounds: 0, blocks: 0, steals: 0 }
  )

  return (
    <div className='StatsDisplay'>
      <h2>Game History</h2>
      {(showAll ? stats : stats.slice(-4)).map((game, idx) => (
        <div key={idx}>
          <p>Points: {game.points}</p>
          <p>Assists: {game.assists}</p>
          <p>Rebounds: {game.rebounds}</p>
          <p>Blocks: {game.blocks}</p>
          <p>Steals: {game.steals}</p>
          <p>Won: {game.won ? 'Yes' : 'No'}</p>
        </div>
      ))}
      <button onClick={() => setShowAll(!showAll)}>{showAll ? 'Show Last 4 Games' : 'Show All Games'}</button>

      {statsSummary && (
        <div>
          <h2>Season Summary</h2>
          <p>Wins: {statsSummary.wins}</p>
          <p>Losses: {statsSummary.losses}</p>
          <p>Win Percentage: {((statsSummary.wins / stats.length) * 100).toFixed(2)}%</p>
          <h3>Averages</h3>
          <p>Points: {statsSummary.averages.points.toFixed(2)}</p>
          <p>Assists: {statsSummary.averages.assists.toFixed(2)}</p>
          <p>Rebounds: {statsSummary.averages.rebounds.toFixed(2)}</p>
          <p>Blocks: {statsSummary.averages.blocks.toFixed(2)}</p>
          <p>Steals: {statsSummary.averages.steals.toFixed(2)}</p>
        </div>
      )}

      {careerHighs && (
        <div>
          <h2>Career Highs</h2>
          <p>Points: {careerHighs.points}</p>
          <p>Assists: {careerHighs.assists}</p>
          <p>Rebounds: {careerHighs.rebounds}</p>
          <p>Blocks: {careerHighs.blocks}</p>
          <p>Steals: {careerHighs.steals}</p>
        </div>
      )}

      <div>
        <h2>Totals</h2>
        <p>Total Points: {totals.points}</p>
        <p>Total Assists: {totals.assists}</p>
        <p>Total Rebounds: {totals.rebounds}</p>
        <p>Total Blocks: {totals.blocks}</p>
        <p>Total Steals: {totals.steals}</p>
        {statsSummary && <p>Total Games: {statsSummary.wins + statsSummary.losses}</p>}
      </div>
    </div>
  )
}

export default App
