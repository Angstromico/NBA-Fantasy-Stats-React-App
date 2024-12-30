import React, { useState } from 'react'
import type { GameStats, CareerHighs, StatsSummary } from '../interfaces'

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

export default StatsDisplay
