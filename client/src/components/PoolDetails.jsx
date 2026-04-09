import { useEffect, useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { DataRow } from './DataRow'

function PoolDetails() {
  const { id } = useParams()
  const [pool, setPool] = useState(null)
  const token = localStorage.getItem('session_token')
  const poolGrid = "grid-cols-[1fr+120px_80px]"

  useEffect(() => {
    fetch(`${import.meta.env.VITE_API_URL}/pools/${id}`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    })
    .then(res => res.json())
    .then(data => setPool(data))
    .catch(err => console.error("Error fetching pool details:", err))
  }, [id, token])

  if (!pool) return <div>Loading pool details...</div>

  return (
    <div>
      <Link to="/" style={{ color: 'blue', textDecoration: 'underline' }}>
        ← Back to Dashboard
      </Link>
      <h1 className="text-2xl font-bold my-4">{pool.name}</h1>
      <div className="mt-6">
        <DataRow isHeader gridClass={poolGrid}>
          <div>Team</div>
          <div className="text-right">Owner</div>
          <div className="text-right">Score</div>
        </DataRow>

        {pool.pool_teams?.map(team => (
          <DataRow key={team.id} to={`/pool_teams/${team.id}`} gridClass={poolGrid}>
            <div className="font-semibold text-blue-600 truncate">{team.team_name}</div>
            <div className="text-right text-gray-600">{team.user?.name}</div>
            <div className="text-right font-mono font-bold">{team.total_score}</div>
          </DataRow>
        ))}
      </div>
    </div>
  )
}

export default PoolDetails