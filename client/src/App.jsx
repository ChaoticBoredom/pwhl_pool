import { BrowserRouter, Routes, Route, Link } from 'react-router-dom'
import { useEffect, useState } from 'react'
import { useAuth } from './context/AuthContext'
import LoginForm from './components/LoginForm'
import PlayerSelection from './components/PlayerSelection'
import PoolDetails from './components/PoolDetails'
import PoolTeamDetails from './components/PoolTeamDetails'

const Dashboard = ({ pools, onLogout }) => (
  <div>
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
      <h1>Dashboard</h1>
      <button onClick={onLogout}>Logout</button>
    </div>
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
);

function App() {
  const { currentUser, token, logout } = useAuth();
  const [pools, setPools] = useState([])

  useEffect(() => {
    if (currentUser && token) {
      fetch(`${import.meta.env.VITE_API_URL}/pools`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      })
        .then(res => res.json())
        .then(data => setPools(data))
        .catch(err => console.log("Fetch error:", err));
    }
  }, [currentUser, token]);

  return (
    <BrowserRouter>
      <div style={{ padding: '40px' }}>
        {!currentUser ? (
          <LoginForm />
        ) : (
        <Routes>
          <Route path="/" element={
            <Dashboard pools={pools} onLogout={logout} />
          } />
          <Route path="pools/:poolId" element={<PoolDetails />} />
          <Route path="pools/:poolId/teams/:teamId" element={<PoolTeamDetails />} />
          <Route path="pools/:poolId/teams/:teamId/select" element={<PlayerSelection />} />
        </Routes>
        )}
      </div>
    </BrowserRouter>
  )
}

export default App;
