import React from 'react'
import type { GameStats } from '../interfaces'
import {
  compareToNBARecords,
  getRecordAchievements,
} from '../utils/recordCalculations'
import type { RecordComparison } from '../utils/recordCalculations'
import './RecordsDisplay.css'

interface RecordsDisplayProps {
  stats: GameStats[]
  congrats: RecordComparison[]
  onDismissCongrats: () => void
}

const formatDate = (date?: string): string => {
  if (!date) {
    return ''
  }
  const parsed = new Date(date)
  if (Number.isNaN(parsed.getTime())) {
    return date
  }
  return parsed.toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  })
}

const formatStreakLabel = (value: number, letter: string): string =>
  value > 0 ? `${letter}${value}` : 'None'

const getCongratsMessage = (comparison: RecordComparison): string => {
  const { record, playerValue } = comparison
  const action =
    playerValue > record.value
      ? 'broke'
      : 'matched (tied)'
  return `Your player ${action} the NBA record for ${record.label} — ${record.holder}'s ${record.value} ${record.unit} (${record.season}) — with ${playerValue} ${record.unit}!`
}

const RecordsDisplay: React.FC<RecordsDisplayProps> = ({
  stats,
  congrats,
  onDismissCongrats,
}) => {
  const achievements = getRecordAchievements(stats)
  const comparisons = compareToNBARecords(achievements)

  const streakCards = [
    {
      id: 'wins',
      title: 'Win Streak',
      current: formatStreakLabel(achievements.currentWinStreak, 'W'),
      best: formatStreakLabel(achievements.longestWinStreak, 'W'),
      range: achievements.longestWinStart
        ? `${formatDate(achievements.longestWinStart)} — ${formatDate(achievements.longestWinEnd)}`
        : '',
    },
    {
      id: 'losses',
      title: 'Loss Streak',
      current: formatStreakLabel(achievements.currentLossStreak, 'L'),
      best: formatStreakLabel(achievements.longestLossStreak, 'L'),
      range: achievements.longestLossStart
        ? `${formatDate(achievements.longestLossStart)} — ${formatDate(achievements.longestLossEnd)}`
        : '',
    },
    ...achievements.scoringStreaks.map((streak) => ({
      id: `pts-${streak.threshold}`,
      title: `${streak.threshold}+ Point Games`,
      current: formatStreakLabel(streak.current, ''),
      best: formatStreakLabel(streak.longest, ''),
      range: streak.longestStart
        ? `${formatDate(streak.longestStart)} — ${formatDate(streak.longestEnd)}`
        : '',
    })),
  ]

  return (
    <section className='RecordsDisplay glass-card'>
      <div className='records-hero'>
        <span className='eyebrow'>Record chase</span>
        <h2>NBA Records</h2>
        <p>
          Follow your player&apos;s career-best streaks and see how they stack
          up against the greatest records in NBA history.
        </p>
      </div>

      {congrats.length > 0 && (
        <div className='congrats-banner' role='status'>
          <div className='congrats-banner-list'>
            {congrats.map((comparison) => (
              <p key={comparison.record.id}>
                🏆 {getCongratsMessage(comparison)}
              </p>
            ))}
          </div>
          <button
            type='button'
            className='congrats-dismiss'
            onClick={onDismissCongrats}
            aria-label='Dismiss congratulations'
          >
            ✕
          </button>
        </div>
      )}

      {stats.length === 0 ? (
        <div className='records-empty-state'>
          <h3>No games logged yet</h3>
          <p>
            Submit games from the tracker to start building streaks and chasing
            NBA records.
          </p>
        </div>
      ) : (
        <>
          <div className='records-section'>
            <h3>Career Top Streaks</h3>
            <div className='streak-cards'>
              {streakCards.map((card) => (
                <div className='streak-card' key={card.id}>
                  <span className='streak-card-title'>{card.title}</span>
                  <div className='streak-card-values'>
                    <div>
                      <span>Current</span>
                      <strong>{card.current}</strong>
                    </div>
                    <div>
                      <span>Best</span>
                      <strong className='best'>{card.best}</strong>
                    </div>
                  </div>
                  {card.range && (
                    <small className='streak-range'>{card.range}</small>
                  )}
                </div>
              ))}
            </div>
          </div>

          <div className='records-section'>
            <h3>Real NBA Records</h3>
            <div className='records-table-shell'>
              <table className='records-table'>
                <thead>
                  <tr>
                    <th scope='col'>Record</th>
                    <th scope='col'>Your Best</th>
                    <th scope='col'>NBA Record</th>
                    <th scope='col'>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {comparisons.map((comparison) => {
                    const { record, playerValue, currentValue, broken, remaining } =
                      comparison
                    return (
                      <tr
                        key={record.id}
                        className={broken ? 'record-broken' : ''}
                      >
                        <th scope='row' data-label='Record'>
                          {record.label}
                          <small>{record.detail}</small>
                        </th>
                        <td data-label='Your Best'>
                          <strong>{playerValue}</strong>
                          {currentValue !== undefined && currentValue > 0 && (
                            <small>
                              Current: {currentValue} {record.unit}
                            </small>
                          )}
                        </td>
                        <td data-label='NBA Record'>
                          <span className='record-holder'>
                            {record.holder}
                            {record.team ? ` (${record.team})` : ''}
                          </span>
                          <small>
                            {record.value} {record.unit} · {record.season}
                          </small>
                        </td>
                        <td data-label='Status'>
                          {broken ? (
                            <span className='record-broken-badge'>
                              🏆 BROKEN
                            </span>
                          ) : (
                            <span className='record-progress'>
                              {remaining} {record.unit} to go
                            </span>
                          )}
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </>
      )}
    </section>
  )
}

export default RecordsDisplay