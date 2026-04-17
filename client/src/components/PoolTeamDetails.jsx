import { useEffect, useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { useAuth } from '../context/AuthContext';
import { DataRow } from './DataRow'
import Player from './Player'

function PoolTeamDetails() {
  const { poolId, teamId } = useParams()
  const [poolTeam, setPoolTeam] = useState(null)
  const { currentUser, token } = useAuth();
  const poolGrid = "grid-cols-[1fr+80px_80px_100px]"

  useEffect(() => {
    fetch(`${import.meta.env.VITE_API_URL}/pool_teams/${teamId}`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    })
    .then(res => res.json())
    .then(data => setPoolTeam(data))
    .catch(err => console.error("Error fetching pool team details:", err))
  }, [teamId, token])

  if (!poolTeam) return <div>Loading pool team details...</div>

  const isOwner = currentUser && poolTeam.owner.id === currentUser;

  return (
    <div>
      <Link to="/" style={{ color: 'blue', textDecoration: 'underline' }}>
        ← Back to Dashboard
      </Link>
      <h1 className="text-2xl font-bold my-4">{poolTeam.team_name}</h1>
      {isOwner && <Link to={`/pools/${poolTeam.pool_id}/teams/${poolTeam.id}/select`}
        className="trade-link bg-purple-600 text-white px-4 py-2 rounded">
        Trade Players
      </Link>}
      <h2 className="text-2xl font-bold my-4">{poolTeam.owner?.name}</h2>
      <div className="mt-6">
        <DataRow isHeader gridClass={poolGrid}>
          <div>Player</div>
          <div className="text-right">Today</div>
          <div className="text-right">Yesterday</div>
          <div className="text-right">Month-to-Date</div>
        </DataRow>

        {poolTeam.current_team?.map(player => (
          <DataRow key={player.league_player_id} gridClass={poolGrid}>
            <Player player={player} />
            <div className="text-right">{player.scores.today.toFixed(2)}</div>
            <div className="text-right">{player.scores.history.yesterday.toFixed(2)}</div>
            <div className="text-right">{player.scores.history.month_to_date.toFixed(2)}</div>
          </DataRow>
        ))}
      </div>
    </div>
  )
}

export default PoolTeamDetails
