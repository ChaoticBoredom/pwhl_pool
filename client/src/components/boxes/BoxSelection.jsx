import { ChevronRight } from "lucide-react";
import { DataRow } from "@c/shared/DataRow";
import Player from "@c/players/Player";

const BoxSelection = ({
  box,
  isCurrentSeason,
  selectedPlayerId,
  onSelect,
  pendingByPlayer = {},
  onExpandDetails,
  isDesktop,
}) => {
  const selectionGrid = "grid-cols-[1fr_80px]";
  const boxRequests = box.players.flatMap(p => pendingByPlayer[p.id] ?? []);
  const hasPending = boxRequests.length > 0;

  return (
    <div className="box-container panel mb-6">
      <div className="box-selection__header">
        <h3>{box.name}</h3>
        {isDesktop && (
          <button
            className={`box-selection__expand-btn ${hasPending ? "box-selection__expand-btn--pending" : ""}`}
            onClick={() => onExpandDetails(
              hasPending ? "trades" : "comparison",
              hasPending
                ? { requests: boxRequests }
                : { boxId: box.id, boxName: box.name, players: box.players },
            )}
            title={hasPending ? "View pending requests" : "Compare players"}
          >
            {hasPending && (
              <span className="box-selection__pending-count">pending</span>
            )}
            <ChevronRight size={16} />
          </button>
        )}
      </div>

      <div className={`player-list ${hasPending ? "player-list--locked" : ""}`}>
        {box.players.map(player => {
          const isSelected = selectedPlayerId === player.id;
          const playerRequests = pendingByPlayer[player.id] ?? [];
          const hasDrop = playerRequests.some(r => r.action === "drop");
          const hasAdd = playerRequests.some(r => r.action === "add");

          return (
            <DataRow
              key={player.id}
              gridClass={selectionGrid}
              onClick={hasPending ? undefined : () => onSelect(player.id)}
            >
              <div className="box-selection__player-row">
                <Player player={player}>
                  <input
                    type="radio"
                    name={`box-${box.id}`}
                    checked={isSelected}
                    onChange={() => onSelect(player.id)}
                    disabled={hasPending}
                  />
                </Player>
                <div className="box-selection__badges">
                  {hasDrop && (
                    <span className="action-badge action-badge--drop">
                      Drop pending
                    </span>
                  )}
                  {hasAdd && (
                    <span className="action-badge action-badge--add">
                      Add pending
                    </span>
                  )}
                </div>
              </div>
              <div className="score-display-vertical">
                <span className="score-label">
                  {isCurrentSeason ? "SEASON-TO-DATE" : "LAST SEASON"}
                </span>
                <span className="stat-value stat-value--lg stat-value--bold">{player.scores.season_to_date.toFixed(2)}</span>
              </div>
            </DataRow>
          );
        })}
      </div>
    </div>
  );
};

export default BoxSelection;
