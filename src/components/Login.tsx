import React, { useState } from 'react'
import bcrypt from 'bcryptjs'
import type { User } from '../interfaces'

interface LoginProps {
  users: User[]
  login: (username: string, password: string) => Promise<boolean>
  saveUsers: (users: User[]) => void
}

const Login: React.FC<LoginProps> = ({ users, login, saveUsers }) => {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [isRegistering, setIsRegistering] = useState(false)

  const handleRegister = async () => {
    if (!username.trim() || !password.trim()) {
      setError('Username and password cannot be empty.')
      setSuccess('')
      return
    }

    if (users.some((u) => u.username === username)) {
      setError('Username already exists.')
      setSuccess('')
      return
    }

    const hashedPassword = await bcrypt.hash(password, 10)
    const newUsers = [...users, { username, hashedPassword }]
    saveUsers(newUsers)
    setSuccess('Registration successful! You can now log in.')
    setError('')
    setPassword('')
    setIsRegistering(false)
  }

  const handleLogin = async () => {
    if (!username.trim() || !password.trim()) {
      setError('Username and password cannot be empty.')
      setSuccess('')
      return
    }

    const success = await login(username, password)
    if (!success) {
      setError('Invalid username or password.')
      setSuccess('')
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (isRegistering) {
      await handleRegister()
    } else {
      await handleLogin()
    }
  }

  return (
    <div className='Login glass-card'>
      <h2>{isRegistering ? 'Create Account' : 'Player Login'}</h2>
      {error && <div className='message error' role='alert'>{error}</div>}
      {success && <div className='message success' role='status'>{success}</div>}
      <form onSubmit={handleSubmit}>
        <div className='form-group'>
          <label htmlFor='username'>Username</label>
          <input
            id='username'
            type='text'
            placeholder='Enter your username'
            value={username}
            onChange={(e) => {
              setUsername(e.target.value)
              setError('')
              setSuccess('')
            }}
          />
        </div>
        <div className='form-group'>
          <label htmlFor='password'>Password</label>
          <input
            id='password'
            type='password'
            placeholder='Enter your password'
            value={password}
            onChange={(e) => {
              setPassword(e.target.value)
              setError('')
              setSuccess('')
            }}
          />
        </div>
        <button type='submit' className='primary-btn'>{isRegistering ? 'Register' : 'Login'}</button>
        <button type='button' className='secondary-btn' onClick={() => {
          setIsRegistering(!isRegistering)
          setError('')
          setSuccess('')
        }}>
          {isRegistering ? 'Already have an account? Login' : "Don't have an account? Register"}
        </button>
      </form>
    </div>
  )
}

export default Login
