import React, { useState } from 'react'
import type { User } from '../interfaces'

const Login: React.FC<{
  users: User[]
  login: (username: string, password: string) => void
  saveUsers: (users: User[]) => void
}> = ({ users, login, saveUsers }) => {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')

  const register = () => {
    if (!username.trim() || !password.trim()) {
      alert('Username and password cannot be empty.')
      return
    }

    if (!users.some((u) => u.username === username)) {
      const newUsers = [...users, { username, password }]
      saveUsers(newUsers)
      alert('Registration successful!')
    } else {
      alert('Username already exists.')
    }
  }

  return (
    <div className='Login'>
      <h2>Login</h2>
      <form
        onSubmit={(e) => {
          e.preventDefault()
          login(username, password)
        }}
      >
        <input type='text' placeholder='Username' value={username} onChange={(e) => setUsername(e.target.value)} />
        <input type='password' placeholder='Password' value={password} onChange={(e) => setPassword(e.target.value)} />
        <button type='submit'>Login</button>
        <button type='button' onClick={register}>
          Register
        </button>
      </form>
    </div>
  )
}

export default Login
