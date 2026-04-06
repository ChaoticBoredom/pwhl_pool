import { useEffect, useState } from 'react'
import LoginForm from './components/LoginForm'

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const [pools, setPools] = useState([])

  const token = localStorage.getItem('session_token')

  const fetchPools = () => {
    fetch(`${import.meta.env.VITE_API_URL}/pools`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    })
      .then(res => res.json())
      .then(data => setPools(data))
      .catch(err => console.log("Fetch error:", err))
  }

  useEffect(() => {
    if (isAuthenticated) {
      fetchPools()
    }
  }, [isAuthenticated])

  return (
    <div style={{ padding: '40px' }}>
      {!isAuthenticated ? (
        <LoginForm onLoginSuccess={() => setIsAuthenticated(true)} />
      ) : (
        // Show Dashboard if authenticated
        <div>
          <h1>Your Dashboard</h1>
          <button onClick={() => setIsAuthenticated(false)}>Logout</button>
          <ul>
            {pools.map(pool => (
              <li key={pool.id}>{pool.name}</li>
            ))}
          </ul>
        </div>
      )}
    </div>
  )
}

export default App