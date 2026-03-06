import React, { useState } from 'react'
import type { GameStats, CareerHighs, StatsSummary, SeasonStats } from '../interfaces'

const StatsDisplay: React.FC<{
  stats: GameStats[]
  careerHighs: CareerHighs | null
  statsSummary: StatsSummary | null
  seasonStats: SeasonStats[]
}> = ({ stats, careerHighs, statsSummary, seasonStats }) => {
  const [showAll, setShowAll] = useState(false)
  const [selectedSeason, setSelectedSeason] = useState<string>('all')

  const totals = stats.reduce(
    (acc, game) => ({
      points: acc.points + game.points,
      assists: acc.assists + game.assists,
      rebounds: acc.rebounds + game.rebounds,
      blocks: acc.blocks + game.blocks,
      steals: acc.steals + game.steals,
      minutes: acc.minutes + game.minutes,
    }),
    { points: 0, assists: 0, rebounds: 0, blocks: 0, steals: 0, minutes: 0 }
  )

  const filteredStats = selectedSeason === 'all' 
    ? stats 
    : stats.filter(game => {
        const seasonYear = game.date ? getSeasonYear(game.date) : 'unknown'
        return seasonYear === selectedSeason
      })

  const getSeasonYear = (dateString: string): string => {
    const date = new Date(dateString)
    const year = date.getFullYear()
    const month = date.getMonth()
    
    if (month >= 9) {
      return `${year}-${(year + 1).toString().slice(-2)}`
    } else {
      return `${year - 1}-${year.toString().slice(-2)}`
    }
  }

  const displayGames = showAll ? filteredStats : filteredStats.slice(-5)

  return (
    <div className='StatsDisplay'>
      <h2>Game History</h2>
      
      {seasonStats.length > 1 && (
        <div className="season-filter">
          <label htmlFor='season-select'>Filter by Season:</label>
          <select 
            id='season-select'
            value={selectedSeason} 
            onChange={(e) => setSelectedSeason(e.target.value)}
          >
            <option value='all'>All Seasons</option>
            {seasonStats.map(season => (
              <option key={season.seasonYear} value={season.seasonYear}>
                {season.seasonYear} Season
              </option>
            ))}
          </select>
        </div>
      )}

      {displayGames.map((game, idx) => (
        <div key={game.id || idx} className={`game-record ${game.isAbsent ? 'absent' : ''}`}>
          <h4>Game {game.gameNumber} - {game.gameType === 'regular' ? 'Regular Season' : 'Playoffs'}</h4>
          <p>Date: {game.date}</p>
          <p>Team: {game.team} vs {game.opponent}</p>
          {game.isAbsent ? (
            <p><strong>Absent: {game.absenceType}</strong></p>
          ) : (
            <>
              <p>Minutes: {game.minutes}</p>
              <p>Points: {game.points}</p>
              <p>Assists: {game.assists}</p>
              <p>Rebounds: {game.rebounds}</p>
              <p>Blocks: {game.blocks}</p>
              <p>Steals: {game.steals}</p>
              <p>Double-Double: {game.isDoubleDouble ? 'Yes' : 'No'}</p>
              <p>Triple-Double: {game.isTripleDouble ? 'Yes' : 'No'}</p>
            </>
          )}
          <p>Result: {game.won ? 'Won' : 'Lost'}</p>
        </div>
      ))}
      
      <button onClick={() => setShowAll(!showAll)}>
        {showAll ? 'Show Last 5 Games' : 'Show All Games'}
      </button>

      {statsSummary && (
        <div className="summary-section">
          <h2>Overall Summary</h2>
          <div className="summary-grid">
            <div>
              <h3>Record</h3>
              <p>Regular Season: {statsSummary.wins}-{statsSummary.losses}</p>
              <p>Playoffs: {statsSummary.playoffWins}-{statsSummary.playoffLosses}</p>
              <p>Win Percentage: {(statsSummary.winPercentage * 100).toFixed(2)}%</p>
              {statsSummary.playoffWins > 0 && (
                <p>Playoff Win Percentage: {(statsSummary.playoffWinPercentage * 100).toFixed(2)}%</p>
              )}
            </div>
            
            <div>
              <h3>Streaks</h3>
              <p>Current Streak: {statsSummary.currentStreak > 0 ? `W${statsSummary.currentStreak}` : statsSummary.currentStreak < 0 ? `L${Math.abs(statsSummary.currentStreak)}` : 'None'}</p>
              <p>Longest Win Streak: {statsSummary.longestWinStreak}</p>
              <p>Longest Loss Streak: {statsSummary.longestLossStreak}</p>
            </div>
          </div>

          <div className="averages-section">
            <h3>Averages</h3>
            <div className="averages-grid">
              <div>
                <h4>Overall</h4>
                <p>Points: {statsSummary.averages.points.toFixed(2)}</p>
                <p>Assists: {statsSummary.averages.assists.toFixed(2)}</p>
                <p>Rebounds: {statsSummary.averages.rebounds.toFixed(2)}</p>
                <p>Blocks: {statsSummary.averages.blocks.toFixed(2)}</p>
                <p>Steals: {statsSummary.averages.steals.toFixed(2)}</p>
                <p>Minutes: {statsSummary.averages.minutes.toFixed(2)}</p>
              </div>
              
              <div>
                <h4>Regular Season</h4>
                <p>Points: {statsSummary.seasonAverages.points.toFixed(2)}</p>
                <p>Assists: {statsSummary.seasonAverages.assists.toFixed(2)}</p>
                <p>Rebounds: {statsSummary.seasonAverages.rebounds.toFixed(2)}</p>
                <p>Blocks: {statsSummary.seasonAverages.blocks.toFixed(2)}</p>
                <p>Steals: {statsSummary.seasonAverages.steals.toFixed(2)}</p>
                <p>Minutes: {statsSummary.seasonAverages.minutes.toFixed(2)}</p>
              </div>
              
              {statsSummary.playoffAverages.points > 0 && (
                <div>
                  <h4>Playoffs</h4>
                  <p>Points: {statsSummary.playoffAverages.points.toFixed(2)}</p>
                  <p>Assists: {statsSummary.playoffAverages.assists.toFixed(2)}</p>
                  <p>Rebounds: {statsSummary.playoffAverages.rebounds.toFixed(2)}</p>
                  <p>Blocks: {statsSummary.playoffAverages.blocks.toFixed(2)}</p>
                  <p>Steals: {statsSummary.playoffAverages.steals.toFixed(2)}</p>
                  <p>Minutes: {statsSummary.playoffAverages.minutes.toFixed(2)}</p>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {seasonStats.length > 0 && (
        <div className="season-stats-section">
          <h2>Season by Season Stats</h2>
          {seasonStats.map(season => (
            <div key={season.seasonYear} className="season-card">
              <h3>{season.seasonYear} Season</h3>
              <p>Games Played: {season.gamesPlayed}</p>
              <p>Record: {season.wins}-{season.losses}</p>
              {season.madePlayoffs && (
                <>
                  <p>Made Playoffs: Yes</p>
                  <p>Playoff Record: {season.playoffWins}-{season.playoffLosses}</p>
                </>
              )}
              <p>Double-Doubles: {season.doubleDoubles}</p>
              <p>Triple-Doubles: {season.tripleDoubles}</p>
              
              <div className="milestones">
                <h4>Statistical Milestones</h4>
                <div className="milestone-grid">
                  <div>
                    <h5>Points Games</h5>
                    {Object.entries(season.statisticalMilestones.points).map(([threshold, count]) => (
                      <p key={threshold}>{threshold}: {count}</p>
                    ))}
                  </div>
                  <div>
                    <h5>Assists Games</h5>
                    {Object.entries(season.statisticalMilestones.assists).map(([threshold, count]) => (
                      <p key={threshold}>{threshold}: {count}</p>
                    ))}
                  </div>
                  <div>
                    <h5>Rebounds Games</h5>
                    {Object.entries(season.statisticalMilestones.rebounds).map(([threshold, count]) => (
                      <p key={threshold}>{threshold}: {count}</p>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {careerHighs && (
        <div className="career-highs-section">
          <h2>Career Highs</h2>
          <div className="highs-grid">
            <p>Points: {careerHighs.points}</p>
            <p>Assists: {careerHighs.assists}</p>
            <p>Rebounds: {careerHighs.rebounds}</p>
            <p>Blocks: {careerHighs.blocks}</p>
            <p>Steals: {careerHighs.steals}</p>
            <p>Minutes: {careerHighs.minutes}</p>
            <p>Career Double-Doubles: {careerHighs.doubleDoubles}</p>
            <p>Career Triple-Doubles: {careerHighs.tripleDoubles}</p>
          </div>
        </div>
      )}

      <div className="totals-section">
        <h2>Career Totals</h2>
        <div className="totals-grid">
          <p>Total Points: {totals.points}</p>
          <p>Total Assists: {totals.assists}</p>
          <p>Total Rebounds: {totals.rebounds}</p>
          <p>Total Blocks: {totals.blocks}</p>
          <p>Total Steals: {totals.steals}</p>
          <p>Total Minutes: {totals.minutes}</p>
          <p>Total Games: {stats.length}</p>
          <p>Games Played: {stats.filter(g => !g.isAbsent).length}</p>
          <p>Games Absent: {stats.filter(g => g.isAbsent).length}</p>
        </div>
      </div>
    </div>
  )
}

export default StatsDisplay
