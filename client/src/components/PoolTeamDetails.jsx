import { useEffect, useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { DataRow } from './DataRow'

function PoolTeamDetails() {
  const { id } = useParams()
  const [poolTeam, setPoolTeam] = useState(null)
  const token = localStorage.getItem('session_token')
  const poolGrid = "grid-cols-[1fr+80px_80px]"

  useEffect(() => {
    fetch(`${import.meta.env.VITE_API_URL}/pool_teams/${id}`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    })
    .then(res => res.json())
    .then(data => setPoolTeam(data))
    .catch(err => console.error("Error fetching pool team details:", err))
  }, [id, token])

  if (!poolTeam) return <div>Loading pool team details...</div>

  return (
    <div>
      <Link to="/" style={{ color: 'blue', textDecoration: 'underline' }}>
        ← Back to Dashboard
      </Link>
      <h1 className="text-2xl font-bold my-4">{poolTeam.team_name}</h1>
      <h2 className="text-2xl font-bold my-4">{poolTeam.owner?.name}</h2>
      <div className="mt-6">
        <DataRow isHeader gridClass={poolGrid}>
          <div>Player</div>
          <div>Yesterday</div>
          <div>Today</div>
        </DataRow>

        {poolTeam.current_team?.map(player => (
          <DataRow gridClass={poolGrid}>
            <div className="font-medium">{player.name}</div>
            <div className="text-right">{player.scores.yesterday}</div>
            <div className="text-right">{player.scores.today}</div>
          </DataRow>
        ))}
      </div>
    </div>
  )
}

export default PoolTeamDetails