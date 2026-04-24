import { Routes, Route, Link, Navigate, useLocation } from 'react-router-dom'
import { useEffect, useState } from 'react'
import { useAuth } from './context/AuthContext'
import AuthForm from './components/AuthForm'
import PlayerSelection from './components/PlayerSelection'
import PoolDetails from './components/PoolDetails'
import PoolTeamDetails from './components/PoolTeamDetails'
import JoinPoolPrompt from './components/JoinPoolPrompt'

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
  const location = useLocation();
  const [pools, setPools] = useState([])

  useEffect(() => {
    if (currentUser && token && location.pathname === "/") {
      fetch(`/api/pools`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      })
        .then(res => res.json())
        .then(data => setPools(data))
        .catch(err => console.log("Fetch error:", err));
    }
  }, [currentUser, token, location.pathname]);

  return (
    <div style={{ padding: '40px' }}>
      <Routes>
        <Route path="/login" element={<AuthForm />} />

        <Route
          path="/pools/:poolId/invite"
          element={!currentUser ? <NavigateToLogin /> : <JoinPoolPrompt />}
        />

        <Route path="/" element={
          currentUser ? <Dashboard pools={pools} onLogout={logout} /> : <Navigate to="/login" replace />
        } />
        <Route path="pools/:poolId" element={<PoolDetails />} />
        <Route path="pools/:poolId/teams/:teamId" element={<PoolTeamDetails />} />
        <Route path="pools/:poolId/teams/:teamId/select" element={<PlayerSelection />} />
      </Routes>
    </div>
  )
}

const NavigateToLogin = () => {
  const location = useLocation();
  return <Navigate to={`/login?next=${encodeURIComponent(location.pathname)}`} replace />;
};

export default App;
