import React from 'react'
import type { GameStats, SeasonStats, StatsSummary } from '../interfaces'

type SummaryRow = {
  id: string
  label: string
  teams: string
  record: string
  playerRecord: string
  missedRecord: string
  regularRecord: string
  playoffRecord: string
  gamesLogged: number
  gamesPlayed: number
  gamesAbsent: number
  points: number
  assists: number
  rebounds: number
  blocks: number
  steals: number
  minutes: number
  doubleDoubles: number
  tripleDoubles: number
  buzzerBeaters: number
  playoffBuzzerBeaters: number
  winPercentage: number
  isCareer: boolean
}

const average = (games: GameStats[], stat: keyof Pick<
  GameStats,
  'points' | 'assists' | 'rebounds' | 'blocks' | 'steals' | 'minutes'
>) => {
  if (games.length === 0) {
    return 0
  }

  return games.reduce((total, game) => total + game[stat], 0) / games.length
}

const formatAverage = (value: number) => value.toFixed(1)

const formatPercentage = (value: number) => `${(value * 100).toFixed(1)}%`

const buildSummaryRow = (
  id: string,
  label: string,
  games: GameStats[],
  isCareer = false,
): SummaryRow => {
  const playedGames = games.filter((game) => !game.isAbsent)
  const missedGames = games.filter((game) => game.isAbsent)
  const regularGames = games.filter((game) => game.gameType === 'regular')
  const playoffGames = games.filter((game) => game.gameType === 'playoffs')
  const wins = games.filter((game) => game.won).length
  const playerWins = playedGames.filter((game) => game.won).length
  const missedWins = missedGames.filter((game) => game.won).length
  const regularWins = regularGames.filter((game) => game.won).length
  const playoffWins = playoffGames.filter((game) => game.won).length
  const teams = Array.from(new Set(games.map((game) => game.team))).join(', ')

  return {
    id,
    label,
    teams: teams || '-',
    record: `${wins}-${games.length - wins}`,
    playerRecord: `${playerWins}-${playedGames.length - playerWins}`,
    missedRecord: `${missedWins}-${missedGames.length - missedWins}`,
    regularRecord: `${regularWins}-${regularGames.length - regularWins}`,
    playoffRecord: `${playoffWins}-${playoffGames.length - playoffWins}`,
    gamesLogged: games.length,
    gamesPlayed: playedGames.length,
    gamesAbsent: missedGames.length,
    points: average(playedGames, 'points'),
    assists: average(playedGames, 'assists'),
    rebounds: average(playedGames, 'rebounds'),
    blocks: average(playedGames, 'blocks'),
    steals: average(playedGames, 'steals'),
    minutes: average(playedGames, 'minutes'),
    doubleDoubles: playedGames.filter((game) => game.isDoubleDouble).length,
    tripleDoubles: playedGames.filter((game) => game.isTripleDouble).length,
    buzzerBeaters: games.filter((game) => game.isBuzzerBeater).length,
    playoffBuzzerBeaters: playoffGames.filter((game) => game.isBuzzerBeater).length,
    winPercentage: games.length ? wins / games.length : 0,
    isCareer,
  }
}

const StatTile: React.FC<{
  label: string
  value: string | number
  tone?: 'primary' | 'secondary' | 'success' | 'fire'
}> = ({ label, value, tone = 'primary' }) => (
  <div className={`summary-tile summary-tile-${tone}`}>
    <span>{label}</span>
    <strong>{value}</strong>
  </div>
)

const StatsSummaryPage: React.FC<{
  stats: GameStats[]
  seasonStats: SeasonStats[]
  statsSummary: StatsSummary | null
}> = ({ stats, seasonStats, statsSummary }) => {
  const seasonRows = seasonStats.map((season) => (
    buildSummaryRow(
      season.seasonYear,
      season.seasonYear,
      [...season.regularSeasonGames, ...season.playoffGames],
    )
  ))
  const careerRow = buildSummaryRow('career', 'Career Total', stats, true)
  const summaryRows = [...seasonRows, careerRow]
  const bestScoringSeason = seasonRows.reduce<SummaryRow | null>(
    (best, row) => (!best || row.points > best.points ? row : best),
    null,
  )

  return (
    <section className='StatsSummaryPage glass-card'>
      <div className='summary-page-hero'>
        <div>
          <span className='eyebrow'>Player analytics</span>
          <h2>Season Summary</h2>
          <p>
            Compare every recorded season against the player&apos;s career
            totals, including player record, missed-game record, team totals,
            availability, averages, and double-double production.
          </p>
        </div>
        <div className='summary-hero-record'>
          <span>Player Record</span>
          <strong>{careerRow.playerRecord}</strong>
          <small>{formatPercentage(statsSummary?.playerWinPercentage || 0)} win rate when active</small>
        </div>
      </div>

      {stats.length === 0 ? (
        <div className='summary-empty-state'>
          <h3>No games logged yet</h3>
          <p>
            Submit regular-season or playoff games from the tracker to populate
            the season summary table.
          </p>
        </div>
      ) : (
        <>
          <div className='summary-kpi-grid'>
            <StatTile label='Logged Games' value={careerRow.gamesLogged} />
            <StatTile label='Games Played' value={careerRow.gamesPlayed} />
            <StatTile label='Games Missed' value={careerRow.gamesAbsent} />
            <StatTile
              label='Team Record'
              value={careerRow.record}
              tone='secondary'
            />
            <StatTile
              label='Career PPG'
              value={formatAverage(statsSummary?.averages.points || 0)}
              tone='secondary'
            />
            <StatTile
              label='Best PPG Season'
              value={bestScoringSeason ? `${bestScoringSeason.label} (${formatAverage(bestScoringSeason.points)})` : '-'}
              tone='success'
            />
            <StatTile
              label='Buzzer Beaters 🔥'
              value={`${careerRow.buzzerBeaters} (${careerRow.playoffBuzzerBeaters} PO)`}
              tone='fire'
            />
          </div>

          <div className='summary-table-shell' role='region' aria-label='Season and career statistics table'>
            <table className='summary-table'>
              <thead>
                <tr>
                  <th scope='col'>Scope</th>
                  <th scope='col'>Team</th>
                  <th scope='col'>Player Record</th>
                  <th scope='col'>Missed Record</th>
                  <th scope='col'>Team Record</th>
                  <th scope='col'>Regular</th>
                  <th scope='col'>Playoffs</th>
                  <th scope='col'>Logged</th>
                  <th scope='col'>Played</th>
                  <th scope='col'>Absent</th>
                  <th scope='col'>PPG</th>
                  <th scope='col'>APG</th>
                  <th scope='col'>RPG</th>
                  <th scope='col'>BPG</th>
                  <th scope='col'>SPG</th>
                  <th scope='col'>MPG</th>
                  <th scope='col'>DD</th>
                  <th scope='col'>TD</th>
                  <th scope='col' title='Buzzer Beaters'>BB</th>
                  <th scope='col' title='Playoff Buzzer Beaters'>BB PO</th>
                </tr>
              </thead>
              <tbody>
                {summaryRows.map((row) => (
                    <tr key={row.id} className={row.isCareer ? 'career-row' : ''}>
                      <th scope='row' data-label='Scope'>{row.label}</th>
                      <td data-label='Team'>{row.teams}</td>
                      <td data-label='Player Record'>{row.playerRecord}</td>
                      <td data-label='Missed Record'>{row.missedRecord}</td>
                      <td data-label='Team Record'>{row.record}</td>
                    <td data-label='Regular'>{row.regularRecord}</td>
                    <td data-label='Playoffs'>{row.playoffRecord}</td>
                    <td data-label='Logged'>{row.gamesLogged}</td>
                    <td data-label='Played'>{row.gamesPlayed}</td>
                    <td data-label='Absent'>{row.gamesAbsent}</td>
                    <td data-label='PPG'>{formatAverage(row.points)}</td>
                    <td data-label='APG'>{formatAverage(row.assists)}</td>
                    <td data-label='RPG'>{formatAverage(row.rebounds)}</td>
                    <td data-label='BPG'>{formatAverage(row.blocks)}</td>
                    <td data-label='SPG'>{formatAverage(row.steals)}</td>
                    <td data-label='MPG'>{formatAverage(row.minutes)}</td>
                    <td data-label='DD'>{row.doubleDoubles}</td>
                    <td data-label='TD'>{row.tripleDoubles}</td>
                    <td data-label='Buzzer Beaters'>{row.buzzerBeaters}</td>
                    <td data-label='Playoff Buzzer Beaters'>{row.playoffBuzzerBeaters}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}
    </section>
  )
}

export default StatsSummaryPage
