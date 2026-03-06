import React from 'react'
import type { SeasonAwards, StatsSummary } from '../interfaces'
import './ComparisonDisplay.css'

interface ComparisonDisplayProps {
  playerStats: StatsSummary | null
  seasonAwards: SeasonAwards | null
  playerTeam: string
  season: string
}

const ComparisonDisplay: React.FC<ComparisonDisplayProps> = ({
  playerStats,
  seasonAwards,
  playerTeam,
  season
}) => {
  if (!playerStats || !seasonAwards) {
    return null
  }

  const formatComparison = (playerValue: number, referenceValue: number, label: string) => {
    const difference = playerValue - referenceValue
    const percentage = referenceValue > 0 ? ((difference / referenceValue) * 100).toFixed(1) : '0'
    const isBetter = difference > 0
    
    return (
      <div className={`comparison-item ${isBetter ? 'better' : 'worse'}`}>
        <span className="label">{label}:</span>
        <span className="player-value">{playerValue.toFixed(1)}</span>
        <span className="vs">vs</span>
        <span className="reference-value">{referenceValue.toFixed(1)}</span>
        <span className={`difference ${isBetter ? 'positive' : 'negative'}`}>
          {isBetter ? '+' : ''}{difference.toFixed(1)} ({isBetter ? '+' : ''}{percentage}%)
        </span>
      </div>
    )
  }

  const getTeamRecord = () => {
    const wins = playerStats.wins
    const losses = playerStats.losses
    return `${wins}-${losses}`
  }

  const compareTeamRecords = () => {
    const playerWins = playerStats.wins
    const championWins = parseInt(seasonAwards.champion.record.split('-')[0])
    const difference = playerWins - championWins
    const percentage = championWins > 0 ? ((difference / championWins) * 100).toFixed(1) : '0'
    
    return (
      <div className={`comparison-item ${difference >= 0 ? 'better' : 'worse'}`}>
        <span className="label">Team Record:</span>
        <span className="player-value">{getTeamRecord()}</span>
        <span className="vs">vs</span>
        <span className="reference-value">{seasonAwards.champion.record} ({seasonAwards.champion.team})</span>
        <span className={`difference ${difference >= 0 ? 'positive' : 'negative'}`}>
          {difference >= 0 ? '+' : ''}{difference} wins ({difference >= 0 ? '+' : ''}{percentage}%)
        </span>
      </div>
    )
  }

  return (
    <div className="ComparisonDisplay">
      <h2>NBA Comparison - {season} Season</h2>
      
      <div className="comparison-section">
        <h3>Team Performance vs Champions</h3>
        {compareTeamRecords()}
        
        <div className="champion-info">
          <p><strong>Champion:</strong> {seasonAwards.champion.team}</p>
          <p><strong>Record:</strong> {seasonAwards.champion.record}</p>
        </div>
      </div>

      <div className="comparison-section">
        <h3>Individual Performance vs Award Winners</h3>
        
        {formatComparison(
          playerStats.averages.points,
          seasonAwards.scoringChampion.ppg,
          `PPG vs ${seasonAwards.scoringChampion.player} (${seasonAwards.scoringChampion.team})`
        )}
        
        {formatComparison(
          playerStats.averages.assists,
          8.0, // Approximate league average for comparison
          `APG vs League Average`
        )}
        
        {formatComparison(
          playerStats.averages.rebounds,
          7.0, // Approximate league average for comparison
          `RPG vs League Average`
        )}
        
        <div className="award-info">
          <div className="award-item">
            <strong>MVP:</strong> {seasonAwards.mvp.player} ({seasonAwards.mvp.team})
          </div>
          <div className="award-item">
            <strong>Scoring Champion:</strong> {seasonAwards.scoringChampion.player} ({seasonAwards.scoringChampion.team}) - {seasonAwards.scoringChampion.ppg} PPG
          </div>
          <div className="award-item">
            <strong>Defensive Player:</strong> {seasonAwards.defensivePlayerOfYear.player} ({seasonAwards.defensivePlayerOfYear.team})
          </div>
          <div className="award-item">
            <strong>Winningest Team:</strong> {seasonAwards.winningestTeam.team} ({seasonAwards.winningestTeam.record})
          </div>
        </div>
      </div>

      <div className="comparison-section">
        <h3>Season Summary</h3>
        <div className="summary-grid">
          <div className="summary-item">
            <span className="label">Your Team:</span>
            <span className="value">{playerTeam}</span>
          </div>
          <div className="summary-item">
            <span className="label">Games Played:</span>
            <span className="value">{playerStats.wins + playerStats.losses}</span>
          </div>
          <div className="summary-item">
            <span className="label">Win %:</span>
            <span className="value">{(playerStats.winPercentage * 100).toFixed(1)}%</span>
          </div>
          <div className="summary-item">
            <span className="label">Current Streak:</span>
            <span className="value">
              {playerStats.currentStreak > 0 ? `W${playerStats.currentStreak}` : 
               playerStats.currentStreak < 0 ? `L${Math.abs(playerStats.currentStreak)}` : 'None'}
            </span>
          </div>
        </div>
      </div>
    </div>
  )
}

export default ComparisonDisplay
