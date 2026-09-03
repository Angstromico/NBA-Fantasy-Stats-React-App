import React, { useMemo } from 'react'
import type { GameStats } from '../interfaces'
import {
  buildLeaderboardViews,
  formatBoardValue,
} from '../utils/leaderboardCalculations'
import type { LeaderboardView } from '../utils/leaderboardCalculations'
import type { LeaderboardDef } from '../data/nbaLeaderboards'
import './AllTimeLeaderboards.css'

interface AllTimeLeaderboardsProps {
  stats: GameStats[]
  playerName: string
}

const GROUP_LABELS: Record<string, string> = {
  'single-game': 'Best Single Games',
  'single-season': 'Best Single Seasons',
  career: 'Career Feats',
  team: 'Team Feats',
}

const GROUP_ORDER = ['single-game', 'single-season', 'career', 'team']

const SEASON_QUALIFIER = '58+ games played that season'

const PLAYER_QUALIFIER_COPY: Partial<Record<string, string>> = {
  'season-ppg': SEASON_QUALIFIER,
  'season-rpg': SEASON_QUALIFIER,
  'season-apg': SEASON_QUALIFIER,
  'season-bpg': SEASON_QUALIFIER,
  'season-spg': SEASON_QUALIFIER,
  'team-season-wins': 'a complete 82-game season',
}

const getBoardCutoff = (board: LeaderboardDef): string => {
  const sorted = [...board.entries].sort(
    (a, b) =>
      b.value - a.value || (a.sortKey || '').localeCompare(b.sortKey || ''),
  )
  const cutoff = sorted[19]
  return cutoff ? `${formatBoardValue(cutoff.value, board)} ${board.unit}` : '—'
}

const MarkStatus: React.FC<{ view: LeaderboardView }> = ({ view }) => {
  const { board, mark, playerPerformances, extraPlayerCount } = view

  if (playerPerformances.length > 0) {
    const extraCopy =
      extraPlayerCount > 0
        ? ` Another ${extraPlayerCount} of your performances also make the board.`
        : ''
    return (
      <p className='lb-mark-status is-on-board' role='status'>
        🏆 You&apos;re on this board — {playerPerformances.length} top-20
        performance{playerPerformances.length === 1 ? '' : 's'} highlighted
        below.{extraCopy}
      </p>
    )
  }

  if (!mark) {
    return null
  }

  if (!mark.eligible) {
    const qualifier = PLAYER_QUALIFIER_COPY[board.id]
    return (
      <p className='lb-mark-status is-qualifier' role='status'>
        <strong>Your best: {formatBoardValue(mark.value, board)} {board.unit}</strong>
        <span>
          over {mark.games} games — {qualifier || 'does not qualify yet'} to
          rank.
        </span>
      </p>
    )
  }

  if (mark.rank !== null) {
    return (
      <p className='lb-mark-status' role='status'>
        <strong>Your best: {formatBoardValue(mark.value, board)} {board.unit}</strong>
        <span>
          {mark.context} · ranks #{mark.rank} all-time — chase the top 20.
        </span>
      </p>
    )
  }

  return null
}

const LeaderboardBoard: React.FC<{ view: LeaderboardView }> = ({ view }) => {
  const { board, rows } = view
  return (
    <div className='lb-board'>
      <div className='lb-board-head'>
        <h3>{board.title}</h3>
        <span className='lb-cutoff'>Top 20 needs {getBoardCutoff(board)}</span>
      </div>
      <p className='lb-board-detail'>{board.detail}</p>
      <MarkStatus view={view} />
      <div className='lb-table-shell'>
        <table className='lb-table'>
          <thead>
            <tr>
              <th scope='col'>Rank</th>
              <th scope='col'>Name</th>
              <th scope='col' className='lb-col-value'>
                Mark
              </th>
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr
                key={row.isPlayer ? `you-${row.rank}-${row.context}` : `r-${row.name}-${row.context}`}
                className={row.isPlayer ? 'lb-you' : ''}
              >
                <td className='lb-rank'>{row.rank}</td>
                <th scope='row'>
                  {row.name}
                  {row.isPlayer && <span className='lb-you-badge'>You</span>}
                  <small>{row.context}</small>
                </th>
                <td className='lb-value lb-col-value'>
                  <strong>
                    {formatBoardValue(row.value, board)} {board.unit}
                  </strong>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {board.note && <p className='lb-note'>{board.note}</p>}
    </div>
  )
}

const AllTimeLeaderboards: React.FC<AllTimeLeaderboardsProps> = ({
  stats,
  playerName,
}) => {
  const views = useMemo(
    () => buildLeaderboardViews(stats, playerName),
    [stats, playerName],
  )
  const hasLoggedGames = stats.length > 0
  const boardsWithPlayer = views.filter(
    (view) => view.playerPerformances.length > 0,
  )

  return (
    <section className='AllTimeLeaderboards'>
      <div className='lb-hero'>
        <span className='eyebrow'>All-time rankings</span>
        <h2>Top 20 Leaderboards</h2>
        <p>
          See how your player&apos;s best games, seasons, and career marks stack
          up against the greatest in NBA history. Every performance that cracks
          a top 20 — not just your single best — is highlighted on its board.
        </p>
        {hasLoggedGames && boardsWithPlayer.length > 0 && (
          <p className='lb-hero-summary' role='status'>
            🏆 You&apos;re currently on {boardsWithPlayer.length} of 11 boards.
          </p>
        )}
      </div>

      {!hasLoggedGames ? (
        <div className='lb-empty-state'>
          <h3>No games logged yet</h3>
          <p>
            Submit games from the tracker to start climbing the all-time
            leaderboards.
          </p>
        </div>
      ) : (
        GROUP_ORDER.map((group) => {
          const groupViews = views.filter((view) => view.board.group === group)
          if (groupViews.length === 0) {
            return null
          }
          return (
            <div className='lb-section' key={group}>
              <h2 className='lb-section-title'>{GROUP_LABELS[group]}</h2>
              <div className='lb-grid'>
                {groupViews.map((view) => (
                  <LeaderboardBoard key={view.board.id} view={view} />
                ))}
              </div>
            </div>
          )
        })
      )}
    </section>
  )
}

export default AllTimeLeaderboards
