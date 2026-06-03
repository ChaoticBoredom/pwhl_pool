import { useState } from "react";
import { PlayerDrawer } from "@c/players/PlayerDrawer";
import TeamBadge from "@c/shared/TeamBadge";
import { useDrawerState } from "@/hooks/useDrawerState";

const WINDOWS = [
  { key: "season_to_date", label: "Season" },
  { key: "month_to_date", label: "Month" },
  { key: "week_to_date", label: "Week" },
  { key: "today", label: "Today" },
];

function ComparisonPanel({ boxName, players, selectedPlayerId, onSelect }) {
  const [sortKey, setSortKey] = useState("season_to_date");
  const [sortDir, setSortDir] = useState("desc");

  const handleSort = (key) => {
    if (sortKey === key) {
      setSortDir(d => d === "desc" ? "asc" : "desc");
    } else {
      setSortKey(key);
      setSortDir("desc");
    }
  };

  const sorted = [...players].sort((a, b) => {
    const av = a.scores[sortKey] ?? 0;
    const bv = b.scores[sortKey] ?? 0;
    return sortDir === "desc" ? bv - av : av - bv;
  });

  const sortIcon = (key) => {
    if (sortKey !== key) return null;
    return sortDir === "desc" ? " ↓" : " ↑";
  };

  return (
    <div className="selection-panel">
      <div className="selection-panel__header">
        <span className="selection-panel__player-name">{boxName}</span>
        <span className="selection-panel__subtitle">Compare</span>
      </div>
      <div className="comparison-table">
        <div className="comparison-table__header">
          <span className="comparison-table__col comparison-table__col--player">Player</span>
          {WINDOWS.map(({ key, label }) => (
            <button
              key={key}
              className={`comparison-table__col comparison-table__col--score comparison-table__sort-btn ${sortKey === key ? "comparison-table__sort-btn--active" : ""}`}
              onClick={() => handleSort(key)}
            >
              {label}{sortIcon(key)}
            </button>
          ))}
        </div>
        {sorted.map(player => {
          const isSelected = player.id === selectedPlayerId;
          return (
            <div
              key={player.id}
              className={`comparison-table__row ${isSelected ? "comparison-table__row--selected" : ""}`}
            >
              <div className="comparison-table__col comparison-table__col--player">
                <span className="comparison-table__name">{player.name}</span>
                <TeamBadge shortCode={player.current_team_short_code} />
              </div>
              {WINDOWS.map(({ key }) => (
                <span key={key} className="comparison-table__col comparison-table__col--score">
                  {player.scores[key].toFixed(2)}
                </span>
              ))}
            </div>
          );
        })}
      </div>
    </div>
  );
}

// panel: { type: "comparison", boxName, players, boxId } |
//        { type: "trades", boxName, requests } |
//        null
export default function SelectionDetailPanel({ panel, poolId, selectedPlayerId, onCancelRequest, isCancelling }) {
  const { drawerState, updateDrawer } = useDrawerState();

  if (!panel) {
    return (
      <div className="selection-panel selection-panel--empty">
        <p className="selection-panel__hint">Click the arrow on a box to compare players</p>
      </div>
    );
  }

  if (panel.type === "comparison") {
    return (
      <ComparisonPanel
        boxName={panel.boxName}
        players={panel.players}
        selectedPlayerId={selectedPlayerId}
      />
    );
  }

  if (panel.type === "trades") {
    const { boxName, requests } = panel;
    const grouped = requests.reduce((acc, r) => {
      if (!acc[r.action]) acc[r.action] = [];
      acc[r.action].push(r);
      return acc;
    }, {});

    return (
      <div className="selection-panel">
        <div className="selection-panel__header">
          <span className="selection-panel__player-name">{boxName}</span>
          <span className="selection-panel__subtitle">Pending requests</span>
        </div>

        {["add", "drop"].map(action => (
          grouped[action]?.length > 0 && (
            <div key={action} className="selection-panel__trade-group">
              <span className="selection-panel__trade-label">
                {action === "add" ? "Adding" : "Dropping"}
              </span>
              {grouped[action].map(request => (
                <div key={request.id} className="selection-panel__trade-row">
                  <div className="selection-panel__trade-player">
                    <span className="player-name">{request.league_player.name}</span>
                    <TeamBadge shortCode={request.league_player.team_short_code} />
                  </div>
                  <button
                    className="btn-primary btn-sm selection-panel__cancel-btn"
                    onClick={() => onCancelRequest(request.id)}
                    disabled={isCancelling}
                  >
                    Cancel
                  </button>
                </div>
              ))}
            </div>
          )
        ))}
      </div>
    );
  }

  return null;
}
