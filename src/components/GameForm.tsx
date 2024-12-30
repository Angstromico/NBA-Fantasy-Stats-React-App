import React, { useState } from 'react'
import type { GameStats } from '../interfaces'

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

export default GameForm
