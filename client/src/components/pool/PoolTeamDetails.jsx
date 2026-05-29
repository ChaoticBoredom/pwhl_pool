import { useState } from "react";
import { useParams, Link, useNavigate } from "react-router-dom";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";
import { DataRow } from "@c/shared/DataRow";
import { EditableField } from "@c/shared/EditableField";
import { GameData } from "@c/shared/GameData";
import { PlayerDrawer } from "@c/players/PlayerDrawer";
import { useDrawerState } from "@/hooks/useDrawerState";
import getTradingState from "@/utils/tradingState";

import Player from "@c/players/Player";

const GRID_MOBILE = "grid-cols-[1fr_80px]";
const GRID_MD = "md:grid-cols-[1fr_100px_100px_80px_100px_80px]"
const poolGrid = `${GRID_MOBILE} ${GRID_MD}`;

function PoolTeamDetails() {
  const { poolId, teamId } = useParams()
  const { currentUser, authHeaders } = useAuth();
  const queryClient = useQueryClient();
  const navigate = useNavigate();

  const [openDrawers, setOpenDrawers] = useState(new Set());
  // Shared state for all drawers
  const { drawerState, updateDrawer } = useDrawerState();

  const toggleDrawer = (id) => {
    setOpenDrawers(prev => {
      const next = new Set(prev);
      next.has(id) ? next.delete(id) : next.add(id);
      return next;
    });
  };

  const { data: poolTeam, isLoading, dataUpdatedAt } = useQuery({
    queryKey: ["pool-team", teamId],
    queryFn: () => fetch(`/api/pool_teams/${teamId}`, { headers: authHeaders }).then((r) => r.json()),
    staleTime: 25_000,
    refetchInterval: (query) => { return query.state.data?.games_active ? 30_000 : false; },
    gcTime: 5 * 60 * 1000, // 5 minutes to store data in the 'cache'
  });

  const { tradingIsBlocked } = getTradingState(poolTeam?.trade_state);

  const { mutateAsync: saveTeamName } = useMutation({
    mutationFn: (newName) => fetch(`/api/pool_teams/${teamId}`, {
      method: "PATCH",
      headers: authHeaders,
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
  const lastFetchedAt = new Date(dataUpdatedAt).toLocaleTimeString();

  return (
    <div className="selection-container">
      <Link to={`/pools/${poolId}`} className="back-to-dashboard">← Back to Pool</Link>

      <div className="selection-header">
        <div>
          <h2 className="page-title">
            {isOwner ? 
            (<EditableField value={poolTeam.team_name} onSave={saveTeamName} />) :
            (poolTeam.team_name)
            }
          </h2>
          <span className="helper-text">Manager: {poolTeam.owner?.name}</span>
          <span className="helper-text">Last Updated At: {lastFetchedAt}</span>
        </div>
        {isOwner && (
          <button
            className="btn-primary btn-top"
            disabled={tradingIsBlocked}
            onClick={() => navigate(`/pools/${poolTeam.pool_id}/teams/${poolTeam.id}/select`)}
          >
            {tradingIsBlocked ? "Trades Closed" : "Trade Players"}
          </button>
        )}
      </div>

      <div className="player-list-container">
        <DataRow isHeader gridClass={`${poolGrid} grid-header`}>
          <div>Player</div>
          <div />
          <div className="score-cell">Today</div>
          <div className="hidden md:block score-cell">Yesterday</div>
          <div className="hidden md:block score-cell">
            <span className="wrap-header">Month-to-Date</span>
          </div>
          <div className="hidden md:block score-cell">
            <span className="wrap-header">Season</span>
          </div>
        </DataRow>

        {poolTeam.current_team?.
          sort((a, b) => a.pool_box_position - b.pool_box_position)?.
          map((player) => {
          const isOpen = openDrawers.has(player.id);
          
          return (
            <div key={player.id} className="player-row-group">
              <DataRow gridClass={poolGrid} onClick={() => toggleDrawer(player.id)}>
                <Player player={player} />
                <GameData gameId={player.games.today?.id} />
                <div className="score-cell">{player.scores.scores.today.toFixed(2)}</div>
                <div className="hidden md:block score-cell">{player.scores.scores.yesterday.toFixed(2)}</div>
                <div className="hidden md:block score-cell">{player.scores.scores.month_to_date.toFixed(2)}</div>
                <div className="hidden md:block score-cell">{player.scores.scores.season_to_date.toFixed(2)}</div>
              </DataRow>
              <div className={`player-drawer-wrapper ${isOpen ? "player-drawer-wrapper--open" : ""}`}>
                <PlayerDrawer
                  player={player}
                  isOpen={isOpen}
                  onClose={() => toggleDrawer(player.id)}
                  drawerState={drawerState}
                  onDrawerChange={updateDrawer}
                />
              </div>
            </div>
          );
        })}
        <DataRow gridClass={`${poolGrid}`}>
          <div className="font-semibold">Total</div>
          <div className="hidden md:block"/>
          <div />
          <div className="hidden md:block"/>
          <div className="hidden md:block"/>
          <div className="score-cell font-bold">{poolTeam.total_score?.toFixed(2)}</div>
        </DataRow>
      </div>
    </div>
  );
}

export default PoolTeamDetails;
