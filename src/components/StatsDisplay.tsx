import React, { useState, useMemo } from 'react'
import type { GameStats, CareerHighs, StatsSummary, SeasonStats, StatisticalMilestones } from '../interfaces'
import { calculateStatisticalMilestones } from '../utils/statsCalculations'

const playedGames = (games: GameStats[]) => games.filter((game) => !game.isAbsent)

const average = (
  games: GameStats[],
  stat: 'points' | 'assists' | 'rebounds' | 'blocks' | 'steals' | 'minutes',
) => {
  const played = playedGames(games)
  if (played.length === 0) {
    return 0
  }

  return played.reduce((total, game) => total + game[stat], 0) / played.length
}

const MilestoneFace: React.FC<{
  title: string
  subtitle: string
  milestones: StatisticalMilestones
  isBack?: boolean
  flipCue: string
}> = ({ title, subtitle, milestones, isBack = false, flipCue }) => (
  <div className={`flip-card-face milestones-face${isBack ? ' flip-card-face-back' : ''}`}>
    <div className='milestones-face-header'>
      <div>
        <h3>{title}</h3>
        <span className='flip-subtitle'>{subtitle}</span>
      </div>
      <span className='milestones-flip-badge'>
        {isBack ? '🔄 Current Season' : '🔄 All Seasons'}
      </span>
    </div>

    <div className='milestone-grid'>
      <div>
        <h5>Points Games</h5>
        {Object.entries(milestones.points).map(([threshold, count]) => {
          const numThreshold = parseInt(threshold, 10)
          if (numThreshold >= 70 && count === 0) return null
          return (
            <p key={threshold} className={count > 0 ? 'milestone-active' : ''}>
              <span>{threshold}</span> <strong>{count}</strong>
            </p>
          )
        })}
      </div>

      <div>
        <h5>Assists Games</h5>
        {Object.entries(milestones.assists).map(([threshold, count]) => (
          <p key={threshold} className={count > 0 ? 'milestone-active' : ''}>
            <span>{threshold}</span> <strong>{count}</strong>
          </p>
        ))}
      </div>

      <div>
        <h5>Rebounds Games</h5>
        {Object.entries(milestones.rebounds).map(([threshold, count]) => (
          <p key={threshold} className={count > 0 ? 'milestone-active' : ''}>
            <span>{threshold}</span> <strong>{count}</strong>
          </p>
        ))}
      </div>

      <div>
        <h5>Defense Games</h5>
        <div className='defense-subgroup'>
          <span className='defense-label'>Steals</span>
          {Object.entries(milestones.steals).map(([threshold, count]) => (
            <p key={`stl-${threshold}`} className={count > 0 ? 'milestone-active' : ''}>
              <span>{threshold}</span> <strong>{count}</strong>
            </p>
          ))}
        </div>
        <div className='defense-subgroup'>
          <span className='defense-label'>Blocks</span>
          {Object.entries(milestones.blocks).map(([threshold, count]) => (
            <p key={`blk-${threshold}`} className={count > 0 ? 'milestone-active' : ''}>
              <span>{threshold}</span> <strong>{count}</strong>
            </p>
          ))}
        </div>
      </div>
    </div>

    {milestones.eliteLines.games.length > 0 && (
      <div className='elite-lines'>
        <h5 className='elite-lines-title'>👑 Ultra-Rare All-Around Lines</h5>
        {milestones.eliteLines.games.map((line, index) => (
          <div key={`${line.date}-${index}`} className={`elite-line elite-line--${line.tier}`}>
            <span className='elite-line-badge'>
              {line.tier === 'doubleQuintuple'
                ? 'DOUBLE QUINTUPLE-DOUBLE'
                : line.tier === 'quintuple'
                  ? 'QUINTUPLE-DOUBLE'
                  : 'QUADRUPLE-DOUBLE'}
            </span>
            <span className='elite-line-stats'>
              {line.date} · {line.points} PTS · {line.assists} AST · {line.rebounds} REB · {line.blocks} BLK · {line.steals} STL
            </span>
          </div>
        ))}
      </div>
    )}

    <span className='flip-cue'>{flipCue}</span>
  </div>
)

const StatsDisplay: React.FC<{
  stats: GameStats[]
  careerHighs: CareerHighs | null
  statsSummary: StatsSummary | null
  seasonStats: SeasonStats[]
  currentSeason?: string
}> = ({ stats, careerHighs, statsSummary, seasonStats, currentSeason }) => {
  const [showAll, setShowAll] = useState(false)
  const [recordCardFlipped, setRecordCardFlipped] = useState(false)
  const [milestonesFlipped, setMilestonesFlipped] = useState(false)
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
        const seasonYear = game.season || (game.date ? getSeasonYear(game.date) : 'unknown')
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

  const trackedSeason = currentSeason || seasonStats[0]?.seasonYear || ''
  const currentSeasonGames = stats.filter((game) => {
    const seasonYear = game.season || (game.date ? getSeasonYear(game.date) : 'unknown')
    return seasonYear === trackedSeason
  })
  const currentSeasonPlayed = currentSeasonGames.filter((game) => !game.isAbsent)
  const currentSeasonMissed = currentSeasonGames.filter((game) => game.isAbsent)
  const currentSeasonPlayoffs = currentSeasonGames.filter(
    (game) => game.gameType === 'playoffs',
  )
  const currentSeasonWins = currentSeasonGames.filter((game) => game.won).length
  const currentSeasonLosses = currentSeasonGames.length - currentSeasonWins
  const currentSeasonPlayerWins = currentSeasonPlayed.filter((game) => game.won).length
  const currentSeasonMissedWins = currentSeasonMissed.filter((game) => game.won).length
  const currentSeasonPlayoffWins = currentSeasonPlayoffs.filter((game) => game.won).length
  const currentSeasonPlayerWinPercentage =
    currentSeasonPlayed.length > 0
      ? currentSeasonPlayerWins / currentSeasonPlayed.length
      : 0
  const currentSeasonMissedWinPercentage =
    currentSeasonMissed.length > 0
      ? currentSeasonMissedWins / currentSeasonMissed.length
      : 0
  const currentSeasonPlayoffWinPercentage =
    currentSeasonPlayoffs.length > 0
      ? currentSeasonPlayoffWins / currentSeasonPlayoffs.length
      : 0
  const currentSeasonWinPercentage =
    currentSeasonGames.length > 0 ? currentSeasonWins / currentSeasonGames.length : 0

  const currentSeasonMilestones = useMemo(
    () => calculateStatisticalMilestones(currentSeasonGames),
    [currentSeasonGames],
  )
  const allSeasonsMilestones = useMemo(
    () => calculateStatisticalMilestones(stats),
    [stats],
  )

  return (
    <div className='StatsDisplay glass-card'>
      <h2>Game Statistics</h2>
      
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
            <p><strong>Absent: {game.absenceType.replace(/_/g, ' ')}</strong></p>
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
              <p>Buzzer Beater: {game.isBuzzerBeater ? '🔥 Yes' : 'No'}</p>
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
            <div
              className={`flip-card${recordCardFlipped ? ' is-flipped' : ''}`}
              role='button'
              tabIndex={0}
              aria-label='Record card. Click to flip between the current season record and career totals.'
              onClick={() => setRecordCardFlipped(!recordCardFlipped)}
              onKeyDown={(event) => {
                if (event.key === 'Enter' || event.key === ' ') {
                  event.preventDefault()
                  setRecordCardFlipped(!recordCardFlipped)
                }
              }}
            >
              <div className='flip-card-inner'>
                <div className='flip-card-face' aria-hidden={recordCardFlipped}>
                  <h3>Current Season</h3>
                  <span className='flip-subtitle'>{trackedSeason}</span>
                  <p>Player Games: {currentSeasonPlayerWins}-{currentSeasonPlayed.length - currentSeasonPlayerWins}</p>
                  <p>Missed Games: {currentSeasonMissedWins}-{currentSeasonMissed.length - currentSeasonMissedWins}</p>
                  <p>Team Total: {currentSeasonWins}-{currentSeasonLosses}</p>
                  {currentSeasonPlayoffs.length > 0 && (
                    <p>Playoffs Team Total: {currentSeasonPlayoffWins}-{currentSeasonPlayoffs.length - currentSeasonPlayoffWins}</p>
                  )}
                  <p>Player Win Percentage: {(currentSeasonPlayerWinPercentage * 100).toFixed(2)}%</p>
                  <p>Team Win Percentage: {(currentSeasonWinPercentage * 100).toFixed(2)}%</p>
                  {currentSeasonMissed.length > 0 && (
                    <p>Missed Games Win Percentage: {(currentSeasonMissedWinPercentage * 100).toFixed(2)}%</p>
                  )}
                  {currentSeasonPlayoffs.length > 0 && (
                    <p>Playoff Win Percentage: {(currentSeasonPlayoffWinPercentage * 100).toFixed(2)}%</p>
                  )}
                  <span className='flip-cue'>Click for career totals</span>
                </div>
                <div
                  className='flip-card-face flip-card-face-back'
                  aria-hidden={!recordCardFlipped}
                >
                  <h3>Career Totals</h3>
                  <p>Player Games: {statsSummary.playerWins}-{statsSummary.playerLosses}</p>
                  <p>Missed Games: {statsSummary.missedWins}-{statsSummary.missedLosses}</p>
                  <p>Team Total: {statsSummary.teamWins}-{statsSummary.teamLosses}</p>
                  <p>Playoffs Team Total: {statsSummary.playoffWins}-{statsSummary.playoffLosses}</p>
                  <p>Player Win Percentage: {(statsSummary.playerWinPercentage * 100).toFixed(2)}%</p>
                  <p>Team Win Percentage: {(statsSummary.winPercentage * 100).toFixed(2)}%</p>
                  {statsSummary.gamesMissed > 0 && (
                    <p>Missed Games Win Percentage: {(statsSummary.missedWinPercentage * 100).toFixed(2)}%</p>
                  )}
                  {statsSummary.playoffWins > 0 && (
                    <p>Playoff Win Percentage: {(statsSummary.playoffWinPercentage * 100).toFixed(2)}%</p>
                  )}
                  <span className='flip-cue'>Click for current season</span>
                </div>
              </div>
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
            {trackedSeason !== '' && (
              <div className='averages-current'>
                <h4>Current Season</h4>
                <span className='averages-note'>
                  {trackedSeason}
                  {currentSeasonPlayed.length > 0 &&
                    ` · ${currentSeasonPlayed.length} game${
                      currentSeasonPlayed.length === 1 ? '' : 's'
                    } played`}
                </span>
                {currentSeasonPlayed.length === 0 ? (
                  <p className='averages-empty'>
                    {currentSeasonGames.length === 0
                      ? 'No games logged yet this season'
                      : 'No games played yet this season'}
                  </p>
                ) : (
                  <>
                    <p>Points: {average(currentSeasonGames, 'points').toFixed(2)}</p>
                    <p>Assists: {average(currentSeasonGames, 'assists').toFixed(2)}</p>
                    <p>Rebounds: {average(currentSeasonGames, 'rebounds').toFixed(2)}</p>
                    <p>Blocks: {average(currentSeasonGames, 'blocks').toFixed(2)}</p>
                    <p>Steals: {average(currentSeasonGames, 'steals').toFixed(2)}</p>
                    <p>Minutes: {average(currentSeasonGames, 'minutes').toFixed(2)}</p>
                  </>
                )}
              </div>
            )}
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
              <p>Team Games Logged: {season.gamesPlayed}</p>
              <p>Player Games Played: {season.playerGamesPlayed}</p>
              <p>Games Missed: {season.gamesMissed}</p>
              <p>Player Record: {season.playerWins}-{season.playerLosses}</p>
              <p>Missed Games Record: {season.missedWins}-{season.missedLosses}</p>
              <p>Team Total Record: {season.teamWins}-{season.teamLosses}</p>
              {season.madePlayoffs && (
                <>
                  <p>Made Playoffs: Yes</p>
                  <p>Playoff Record: {season.playoffWins}-{season.playoffLosses}</p>
                </>
              )}
              <p>Double-Doubles: {season.doubleDoubles}</p>
              <p>Triple-Doubles: {season.tripleDoubles}</p>
            </div>
          ))}
        </div>
      )}

      {stats.length > 0 && (
        <div className="milestones-section">
          <h2>Statistical Milestones</h2>
          <div
            className={`flip-card milestones-flip-card${milestonesFlipped ? ' is-flipped' : ''}`}
            role='button'
            tabIndex={0}
            aria-label='Statistical milestones card. Click to flip between current season and all seasons totals.'
            onClick={() => setMilestonesFlipped(!milestonesFlipped)}
            onKeyDown={(event) => {
              if (event.key === 'Enter' || event.key === ' ') {
                event.preventDefault()
                setMilestonesFlipped(!milestonesFlipped)
              }
            }}
          >
            <div className='flip-card-inner'>
              <MilestoneFace
                title='Statistical Milestones'
                subtitle={`Current Season (${trackedSeason || 'Active'})`}
                milestones={currentSeasonMilestones}
                flipCue='Click to flip and view all seasons totals 🔄'
              />
              <MilestoneFace
                title='Statistical Milestones'
                subtitle='All Seasons (Career Cumulative)'
                milestones={allSeasonsMilestones}
                isBack
                flipCue='Click to flip and return to current season 🔄'
              />
            </div>
          </div>
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
          <p>Total Buzzer Beaters: {stats.filter(g => g.isBuzzerBeater).length} 🔥</p>
        </div>
      </div>
    </div>
  )
}

export default StatsDisplay
