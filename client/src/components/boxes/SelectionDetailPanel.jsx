import { useState } from "react";
import TeamBadge from "@c/shared/TeamBadge";
import TradesPanel from "@c/trade_requests/TradesPanel";

const WINDOWS = [
  { key: "season_to_date", label: "Season" },
  { key: "month_to_date", label: "Month" },
  { key: "week_to_date", label: "Week" },
  { key: "yesterday", label: "Yesterday" },
];

function ComparisonPanel({ boxName, players, selectedPlayerId }) {
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
    <div className="panel">
      <div className="panel__header panel__header--gap-wrap">
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
//        { type: "trades", requests } |
//        null
export default function SelectionDetailPanel({
  panel,
  boxes,
  tradeRequests,
  selectedPlayerId,
  onCancelRequest,
  isCancelling,
}) {
  if (!panel) {
    return (
      <div className="panel selection-panel--empty">
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
    return (
      <div className="panel">
        <div className="panel__header panel__header--gap-wrap">
          <span className="selection-panel__player-name">Pending Requests</span>
        </div>
        <TradesPanel
          requests={tradeRequests}
          boxes={boxes}
          onCancel={onCancelRequest}
          isCancelling={isCancelling}
        />
      </div>
    );
  }

  return null;
}
