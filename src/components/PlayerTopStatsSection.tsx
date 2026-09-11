import React, { useState, useMemo } from 'react'
import type { GameStats } from '../interfaces'
import {
  calculatePlayerTopStats,
  type TopStatScope,
  type TopGamePerformance,
  type ThresholdStreak,
  type StreakDetail,
} from '../utils/playerTopStatsCalculations'
import './PlayerTopStatsSection.css'

type StatCategory = 'points' | 'assists' | 'rebounds' | 'steals' | 'blocks' | 'minutes' | 'buzzerBeaters'

interface PlayerTopStatsSectionProps {
  stats: GameStats[]
}

const formatDate = (dateString?: string): string => {
  if (!dateString) return '-'
  const parts = dateString.split('-')
  if (parts.length === 3) {
    return `${parts[1]}/${parts[2]}/${parts[0]}`
  }
  return dateString
}

const GamePerformanceCard: React.FC<{
  item: TopGamePerformance
  highlightStat: string
}> = ({ item, highlightStat }) => {
  const { game, rank, value } = item

  return (
    <div className={`top-game-card glass-card rank-${rank}`}>
      <div className='top-game-header'>
        <div className='rank-badge'>#{rank}</div>
        <div className='stat-highlight'>
          <strong>{value}</strong>
          <span>{highlightStat}</span>
        </div>
        <div className={`result-tag ${game.won ? 'win' : 'loss'}`}>
          {game.won ? 'W' : 'L'}
        </div>
      </div>

      <div className='top-game-matchup'>
        <span className='matchup-prefix'>vs</span>
        <span className='opponent-name'>{game.opponent || 'Opponent'}</span>
      </div>

      <div className='top-game-meta'>
        <span>{formatDate(game.date)}</span>
        <span>{game.season || '-'}</span>
        <span className='game-type-tag'>{game.gameType === 'regular' ? 'Regular' : 'Playoffs'}</span>
      </div>

      <div className='top-game-box-score'>
        <div>
          <span>PTS</span>
          <strong>{game.points}</strong>
        </div>
        <div>
          <span>AST</span>
          <strong>{game.assists}</strong>
        </div>
        <div>
          <span>REB</span>
          <strong>{game.rebounds}</strong>
        </div>
        <div>
          <span>STL</span>
          <strong>{game.steals}</strong>
        </div>
        <div>
          <span>BLK</span>
          <strong>{game.blocks}</strong>
        </div>
        <div>
          <span>MIN</span>
          <strong>{game.minutes}</strong>
        </div>
      </div>
    </div>
  )
}

const StreakCard: React.FC<{
  title: string
  streak: StreakDetail
  tone?: 'positive' | 'negative' | 'neutral'
  unit?: string
  subtitle?: string
}> = ({ title, streak, tone = 'positive', unit = 'Games', subtitle }) => {
  const hasStreak = streak.length > 0

  return (
    <div className={`streak-card glass-card streak-${tone}`}>
      <div className='streak-card-top'>
        <h4>{title}</h4>
        {subtitle && <span className='streak-subtitle'>{subtitle}</span>}
      </div>

      <div className='streak-value-row'>
        <strong className='streak-number'>{streak.length}</strong>
        <span className='streak-unit'>{unit}</span>
        {streak.current > 0 && (
          <span className='streak-active-pill'>Active: {streak.current}</span>
        )}
      </div>

      {hasStreak && streak.startDate && streak.endDate ? (
        <div className='streak-span-info'>
          <p>
            <span>From:</span> {formatDate(streak.startDate)} {streak.startOpponent ? `(${streak.startOpponent})` : ''}
          </p>
          <p>
            <span>To:</span> {formatDate(streak.endDate)} {streak.endOpponent ? `(${streak.endOpponent})` : ''}
          </p>
          {streak.startSeason && (
            <p className='streak-season-tag'>
              {streak.startSeason === streak.endSeason
                ? streak.startSeason
                : `${streak.startSeason} → ${streak.endSeason}`}
            </p>
          )}
        </div>
      ) : (
        <p className='streak-none'>No streaks recorded yet</p>
      )}

      {streak.absenceReasons && streak.absenceReasons.length > 0 && (
        <div className='absence-reasons-list'>
          <span>Reasons:</span> {streak.absenceReasons.join(', ')}
        </div>
      )}
    </div>
  )
}

const ThresholdStreakItem: React.FC<{ item: ThresholdStreak }> = ({ item }) => {
  const hasStreak = item.longest > 0

  return (
    <div className='threshold-streak-item glass-card'>
      <div className='threshold-header'>
        <span className='threshold-label'>{item.label}</span>
        {item.current > 0 && (
          <span className='current-streak-badge'>🔥 {item.current} current</span>
        )}
      </div>

      <div className='threshold-body'>
        <strong className='threshold-number'>{item.longest}</strong>
        <span className='threshold-unit'>consecutive games</span>
      </div>

      {hasStreak && item.startDate && item.endDate ? (
        <div className='threshold-dates'>
          <span>{formatDate(item.startDate)} → {formatDate(item.endDate)}</span>
          {item.startOpponent && item.endOpponent && (
            <span className='threshold-matchups'>
              vs {item.startOpponent} to vs {item.endOpponent}
            </span>
          )}
        </div>
      ) : (
        <div className='threshold-dates none'>Not yet achieved</div>
      )}
    </div>
  )
}

const PlayerTopStatsSection: React.FC<PlayerTopStatsSectionProps> = ({ stats }) => {
  const [scope, setScope] = useState<TopStatScope>('all')
  const [selectedStatCategory, setSelectedStatCategory] = useState<StatCategory>('points')

  const topStats = useMemo(() => calculatePlayerTopStats(stats, scope), [stats, scope])

  const currentCategoryGames = useMemo(() => {
    switch (selectedStatCategory) {
      case 'points':
        return topStats.topScoringGames
      case 'assists':
        return topStats.topAssistsGames
      case 'rebounds':
        return topStats.topReboundsGames
      case 'steals':
        return topStats.topStealsGames
      case 'blocks':
        return topStats.topBlocksGames
      case 'minutes':
        return topStats.topMinutesGames
      case 'buzzerBeaters':
        return topStats.buzzerBeaterGames
      default:
        return topStats.topScoringGames
    }
  }, [selectedStatCategory, topStats])

  const categoryLabel = useMemo(() => {
    switch (selectedStatCategory) {
      case 'points':
        return 'Points'
      case 'assists':
        return 'Assists'
      case 'rebounds':
        return 'Rebounds'
      case 'steals':
        return 'Steals'
      case 'blocks':
        return 'Blocks'
      case 'minutes':
        return 'Minutes'
      case 'buzzerBeaters':
        return 'Buzzer Beaters'
      default:
        return 'Points'
    }
  }, [selectedStatCategory])

  if (stats.length === 0) {
    return null
  }

  return (
    <section className='PlayerTopStatsSection glass-card' aria-label='Player Top Stats and Records'>
      <div className='section-intro'>
        <div>
          <span className='eyebrow'>Player Milestones & Extremes</span>
          <h3>Top Stats, Streaks & Outings</h3>
          <p>
            Explore single-game records, threshold streaks, win/loss runs, and notable outings
            across your entire career or filtered by format.
          </p>
        </div>

        <div className='scope-switcher' role='tablist' aria-label='Stats Scope'>
          <button
            type='button'
            role='tab'
            aria-selected={scope === 'all'}
            className={scope === 'all' ? 'active' : ''}
            onClick={() => setScope('all')}
          >
            All Games
          </button>
          <button
            type='button'
            role='tab'
            aria-selected={scope === 'regular'}
            className={scope === 'regular' ? 'active' : ''}
            onClick={() => setScope('regular')}
          >
            Regular Season
          </button>
          <button
            type='button'
            role='tab'
            aria-selected={scope === 'playoffs'}
            className={scope === 'playoffs' ? 'active' : ''}
            onClick={() => setScope('playoffs')}
          >
            Playoffs
          </button>
        </div>
      </div>

      {/* Top Single Games Section */}
      <div className='subsection-card'>
        <div className='subsection-header'>
          <h4>🌟 Top Single-Game Performances</h4>
          <span className='subsection-hint'>Select a category to view your top 5 games</span>
        </div>

        <div className='category-pills'>
          <button
            type='button'
            className={selectedStatCategory === 'points' ? 'active' : ''}
            onClick={() => setSelectedStatCategory('points')}
          >
            Points
          </button>
          <button
            type='button'
            className={selectedStatCategory === 'assists' ? 'active' : ''}
            onClick={() => setSelectedStatCategory('assists')}
          >
            Assists
          </button>
          <button
            type='button'
            className={selectedStatCategory === 'rebounds' ? 'active' : ''}
            onClick={() => setSelectedStatCategory('rebounds')}
          >
            Rebounds
          </button>
          <button
            type='button'
            className={selectedStatCategory === 'steals' ? 'active' : ''}
            onClick={() => setSelectedStatCategory('steals')}
          >
            Steals
          </button>
          <button
            type='button'
            className={selectedStatCategory === 'blocks' ? 'active' : ''}
            onClick={() => setSelectedStatCategory('blocks')}
          >
            Blocks
          </button>
          <button
            type='button'
            className={selectedStatCategory === 'minutes' ? 'active' : ''}
            onClick={() => setSelectedStatCategory('minutes')}
          >
            Minutes
          </button>
          <button
            type='button'
            className={`buzzer-pill ${selectedStatCategory === 'buzzerBeaters' ? 'active' : ''}`}
            onClick={() => setSelectedStatCategory('buzzerBeaters')}
          >
            Buzzer Beaters 🔥
          </button>
        </div>

        {currentCategoryGames.length === 0 ? (
          <div className='empty-category-notice'>
            <p>No games recorded for {categoryLabel} in this scope yet.</p>
          </div>
        ) : (
          <div className='top-games-grid'>
            {currentCategoryGames.map((item) => (
              <GamePerformanceCard
                key={`${item.game.id}-${item.rank}`}
                item={item}
                highlightStat={item.statLabel}
              />
            ))}
          </div>
        )}
      </div>

      {/* Threshold Streaks Section */}
      <div className='subsection-card'>
        <div className='subsection-header'>
          <h4>🔥 Milestone & Threshold Streaks</h4>
          <span className='subsection-hint'>
            Consecutive games played achieving statistical milestones
          </span>
        </div>

        <div className='thresholds-group'>
          <h5>Scoring Streaks</h5>
          <div className='thresholds-grid'>
            {topStats.scoringStreaks.map((item) => (
              <ThresholdStreakItem key={item.label} item={item} />
            ))}
          </div>
        </div>

        <div className='thresholds-group'>
          <h5>Playmaking & Glass Streaks</h5>
          <div className='thresholds-grid'>
            {topStats.playmakingStreaks.map((item) => (
              <ThresholdStreakItem key={item.label} item={item} />
            ))}
            {topStats.reboundingStreaks.map((item) => (
              <ThresholdStreakItem key={item.label} item={item} />
            ))}
          </div>
        </div>

        <div className='thresholds-group'>
          <h5>All-Around & Defensive Streaks</h5>
          <div className='thresholds-grid'>
            {topStats.allAroundStreaks.map((item) => (
              <ThresholdStreakItem key={item.label} item={item} />
            ))}
            {topStats.defenseStreaks.map((item) => (
              <ThresholdStreakItem key={item.label} item={item} />
            ))}
          </div>
        </div>
      </div>

      {/* Team & Availability Runs */}
      <div className='subsection-card'>
        <div className='subsection-header'>
          <h4>⚡ Winning & Availability Streaks</h4>
          <span className='subsection-hint'>Longest streaks of team and player performance</span>
        </div>

        <div className='streaks-grid'>
          <StreakCard
            title='Team Win Streak'
            subtitle='Consecutive franchise victories'
            streak={topStats.teamWinStreak}
            tone='positive'
          />
          <StreakCard
            title='Active Player Win Streak'
            subtitle='Wins with player on the court'
            streak={topStats.playerWinStreak}
            tone='positive'
          />
        </div>
      </div>

      {/* Bad Stats & Adversity Section */}
      <div className='subsection-card adversity-card'>
        <div className='subsection-header'>
          <h4>❄️ Adversity & Cold Outings</h4>
          <span className='subsection-hint'>
            Longest cold spells, missed stretches, and lowest scoring games played
          </span>
        </div>

        <div className='streaks-grid'>
          <StreakCard
            title='Team Loss Streak'
            subtitle='Consecutive franchise defeats'
            streak={topStats.teamLossStreak}
            tone='negative'
          />
          <StreakCard
            title='Player Loss Streak'
            subtitle='Consecutive losses while active'
            streak={topStats.playerLossStreak}
            tone='negative'
          />
          <StreakCard
            title='Longest Absence Streak'
            subtitle='Consecutive games missed'
            streak={topStats.absenceStreak}
            tone='neutral'
          />
        </div>

        <div className='worst-games-wrap'>
          <h5>Coldest Scoring Outings (Games Played)</h5>
          {topStats.worstScoringGames.length === 0 ? (
            <p className='streak-none'>No played games recorded yet</p>
          ) : (
            <div className='top-games-grid'>
              {topStats.worstScoringGames.map((item) => (
                <GamePerformanceCard
                  key={`worst-${item.game.id}-${item.rank}`}
                  item={item}
                  highlightStat='PTS'
                />
              ))}
            </div>
          )}
        </div>
      </div>
    </section>
  )
}

export default PlayerTopStatsSection
