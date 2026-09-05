import { useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";
import { usePool } from "@/context/PoolContext";
import { DataRow } from "@c/shared/DataRow";
import { EditableField } from "@c/shared/EditableField";
import { GameData } from "@c/shared/GameData";
import { PlayerStatsDrawer } from "@c/players/PlayerStatsDrawer";
import { useDrawerState } from "@/hooks/useDrawerState";
import { formatDate, formatDateRange } from "@/utils/formatDate";
import getTradingState from "@/utils/tradingState";

import Player from "@c/players/Player";

const poolTeamColumns = [
  { width: "1fr" },
  { width: "80px" },
  { width: "80px" },
  { width: "90px", hideOnMobile: true },
  { width: "90px", hideOnMobile: true },
  { width: "80px", hideOnMobile: true },
];

function PoolTeamDetails() {
  const { teamId } = useParams()
  const { currentUser, authHeaders } = useAuth();
  const queryClient = useQueryClient();
  const navigate = useNavigate();

  const [openDrawers, setOpenDrawers] = useState(new Set());
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
    gcTime: 5 * 60 * 1000,
  });

  const { pool } = usePool();
   const { tradingIsBlocked, tradingIsPendingApproval } = getTradingState(poolTeam?.trade_state);

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
  const lastFetchedAt = formatDate(dataUpdatedAt);

  return (
    <div className="selection-container">
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
          {isOwner && pool.next_trade_window && (
            <span className="helper-text">
              Next Trade Window: {formatDateRange(pool.next_trade_window.window_start, pool.next_trade_window.window_end)}
            </span>
          )}
          {isOwner && tradingIsPendingApproval && (
            <span className="helper-text">
              Trades requested now will be pending until approved by the commissioner.
            </span>
          )}
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
        <DataRow columns={poolTeamColumns} isHeader>
          <div>Player</div>
          <div />
          <div className="score-cell">Today</div>
          <div className="score-cell">Yesterday</div>
          <div className="score-cell"><span className="wrap-header">Month-to-Date</span></div>
          <div className="score-cell">Season</div>
        </DataRow>

        {poolTeam.current_team?.
          sort((a, b) => a.pool_box_position - b.pool_box_position)?.
          map((player) => {
          const isOpen = openDrawers.has(player.id);

          return (
            <div key={player.id} className="player-row-group">
              <DataRow columns={poolTeamColumns} onClick={() => toggleDrawer(player.id)}>
                <Player player={player} />
                <GameData gameId={player.games.today?.id} />
                <div className="stat-value">{player.scores.scores.today.toFixed(2)}</div>
                <div className="stat-value">{player.scores.scores.yesterday.toFixed(2)}</div>
                <div className="stat-value">{player.scores.scores.month_to_date.toFixed(2)}</div>
                <div className="stat-value stat-value--bold">{player.scores.scores.season_to_date.toFixed(2)}</div>
              </DataRow>
              <div className={`player-drawer-wrapper ${isOpen ? "player-drawer-wrapper--open" : ""}`}>
                <PlayerStatsDrawer
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
        <DataRow columns={poolTeamColumns}>
          <div className="font-semibold">Total</div>
          <div />
          <div />
          <div />
          <div />
          <div className="stat-value stat-value--bold">{poolTeam.total_score?.toFixed(2)}</div>
        </DataRow>
      </div>
    </div>
  );
}

export default PoolTeamDetails;
