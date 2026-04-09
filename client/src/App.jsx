import { BrowserRouter, Routes, Route, Link } from 'react-router-dom'
import { useEffect, useState } from 'react'
import LoginForm from './components/LoginForm'
import PoolDetails from './components/PoolDetails'
import PoolTeamDetails from './components/PoolTeamDetails'

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(!!localStorage.getItem('session_token'))
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
    <BrowserRouter>
      <div style={{ padding: '40px' }}>
        {!isAuthenticated ? (
          <LoginForm onLoginSuccess={() => setIsAuthenticated(true)} />
        ) : (
        <Routes>
          <Route path="/" element={
          // Show Dashboard if authenticated
            <div>
              <h1>Your Dashboard</h1>
              <button onClick={() => setIsAuthenticated(false)}>Logout</button>
              <ul>
                {pools.map(pool => (
                  <li key={pool.id} style={{ margin: '10px 0' }}>
                    <Link to={`/pools/${pool.id}`} style={{ fontWeight: 'bold'}}>
                      {pool.name}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          } />
          <Route path="pools/:id" element={<PoolDetails />} />
          <Route path="pool_teams/:id" element={<PoolTeamDetails />} />
        </Routes>
        )}
      </div>
    </BrowserRouter>
  )
}

export default App