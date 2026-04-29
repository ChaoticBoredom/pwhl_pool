import { useParams, Link } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useAuth } from '../context/AuthContext';
import { DataRow } from './DataRow';
import { EditableField } from './EditableField';
import { GameData } from "./GameData";
import Player from "./Player";

const GRID_MOBILE = "grid-cols[1fr_80px]";
const GRID_MD = "md:grid-cols-[1fr_80px_100px_80px_80px_100px_80px]"
const poolGrid = `${GRID_MOBILE} ${GRID_MD}`;


function PoolTeamDetails() {
  const { poolId, teamId } = useParams()
  const { currentUser, authHeaders } = useAuth();
  const queryClient = useQueryClient();

  const { data: poolTeam, isLoading } = useQuery({
    queryKey: ["pool-team", teamId],
    queryFn: () => fetch(`/api/pool_teams/${teamId}`, { headers: authHeaders }).then((r) => r.json()),
    staleTime: 0,
    gcTime: 0,
  });

  const { mutateAsync: saveTeamName } = useMutation({
    mutationFn: (newName) => fetch(`api/pool_tems/${teamId}`, {
      method: "PATCH",
      authHeaders,
      body: JSON.stringify({ team_name: newName }),
    }).then((r) => r.json()),
    onSuccess: (updated) => {
      queryClient.setQueryData(["pool-team", teamId], (prev) => ({
        ...prev,
        team_name: updated.team_name,
      }));
    },
  });

  if (isLoading || !poolTeam) return <div>Loading pool team details...</div>

  const isOwner = currentUser && poolTeam?.owner?.id === currentUser;

  return (
    <div className="selection-container">
      <Link to="/" className="back-to-dashboard">← Back to Dashboard</Link>

      <div className="selection-header">
        <div>
          <h1>
            {isOwner ? 
            (<EditableField value={poolTeam.team_name} onSave={saveTeamName} />) :
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
          <div />
          <div />
          <div className="score-cell">Today</div>
          <div className="hidden md:block score-cell">Yesterday</div>
          <div className="hidden md:block score-cell">
            <span className="wrap-header">Month-to-Date</span>
          </div>
          <div className="hidden md:blockscore-cell">
            <span className="wrap-header">Season</span>
          </div>
        </DataRow>

        {poolTeam.current_team?.map(player => (
          <DataRow key={player.league_player_id} gridClass={`${poolGrid} grid-row`}>
            <Player player={player} />
            <GameData gameId={player.games.today?.id} />
            <GameData gameId={player.games.upcoming?.id} />
            <div className="score-cell">{player.scores.scores.today.toFixed(2)}</div>
            <div className="hidden md:block score-cell">{player.scores.scores.yesterday.toFixed(2)}</div>
            <div className="hidden md:block score-cell">{player.scores.scores.month_to_date.toFixed(2)}</div>
            <div className="hidden md:block score-cell">{player.scores.scores.season_to_date.toFixed(2)}</div>
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
  );
}

export default PoolTeamDetails;
