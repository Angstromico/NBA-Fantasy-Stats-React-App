// MVP Race Fantasy NBA Player App

import React, { useState, useEffect } from 'react'
import { Login, GameForm, StatsDisplay } from './components'
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
        <p>Welcome, {currentUser}</p>
        <button onClick={logout}>Logout</button>
      </header>
      <GameForm addGameStats={addGameStats} />
      <StatsDisplay stats={stats} careerHighs={careerHighs} statsSummary={statsSummary} />
    </div>
  )
}

export default App
