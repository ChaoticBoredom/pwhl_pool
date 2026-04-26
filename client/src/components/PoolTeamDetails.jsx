import { useEffect, useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { useAuth } from '../context/AuthContext';
import { DataRow } from './DataRow';
import { EditableField } from './EditableField';
import Player from './Player'

function PoolTeamDetails() {
  const { poolId, teamId } = useParams()
  const [poolTeam, setPoolTeam] = useState(null)
  const { currentUser, token } = useAuth();
  const poolGrid = "grid-cols-[1fr+80px_80px_100px_80px]"

  useEffect(() => {
    fetch(`/api/pool_teams/${teamId}`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    })
    .then(res => res.json())
    .then(data => setPoolTeam(data))
    .catch(err => console.error("Error fetching pool team details:", err))
  }, [teamId, token])

  const changeTeamName = async (newValue) => {
    const response = await fetch(`/api/pool_teams/${teamId}`, {
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ team_name: newValue })
    });

    if (!response.ok) {
      console.log("Pool team update error:");
    }

    return await response.json()
  }

  if (!poolTeam) return <div>Loading pool team details...</div>

  const isOwner = currentUser && poolTeam.owner.id === currentUser;

  return (
    <div className="selection-container">
      <Link to="/" className="back-to-dashboard">← Back to Dashboard</Link>

      <div className="selection-header">
        <div>
          <h1 style={{ margin: 0 }}>
            {isOwner ? 
            (<EditableField initialValue={poolTeam.team_name} onSave={changeTeamName} />) :
            (poolTeam.team_name)
            }
          </h1>
          <span className="helper-text">Manager: {poolTeam.owner?.name}</span>
        </div>
        {isOwner && (
          <Link to={`/pools/${poolTeam.pool_id}/teams/${poolTeam.id}/select`} className="btn-primary btn-top">
            Trade Players
          </Link>
        )}
      </div>

      <div className="player-list-container">
        <DataRow isHeader gridClass={`${poolGrid} grid-header`}>
          <div>Player</div>
          <div className="score-cell">Today</div>
          <div className="score-cell">Yesterday</div>
          <div className="score-cell">
            <span className="wrap-header">Month-to-Date</span>
          </div>
          <div className="score-cell">
            <span className="wrap-header">Season</span>
          </div>
        </DataRow>

        {poolTeam.current_team?.map(player => (
          <DataRow key={player.league_player_id} gridClass={`${poolGrid} grid-row`}>
            <Player player={player} />
            <div className="score-cell">{player.scores.scores.today.toFixed(2)}</div>
            <div className="score-cell">{player.scores.scores.yesterday.toFixed(2)}</div>
            <div className="score-cell">{player.scores.scores.month_to_date.toFixed(2)}</div>
            <div className="score-cell">{player.scores.scores.season_to_date.toFixed(2)}</div>
          </DataRow>
        ))}
        <DataRow gridClass={`${poolGrid}`}>
          <div>Total</div>
          <div />
          <div />
          <div />
          <div className="score-cell">{poolTeam.total_score.toFixed(2)}</div>
        </DataRow>
      </div>
    </div>
  )
}

export default PoolTeamDetails
