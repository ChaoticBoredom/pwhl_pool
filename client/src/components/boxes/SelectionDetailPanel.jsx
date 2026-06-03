import { useState } from "react";
import { PlayerDrawer } from "@c/players/PlayerDrawer";
import TeamBadge from "@c/shared/TeamBadge";
import { useDrawerState } from "@/hooks/useDrawerState";

export default function SelectionDetailPanel({ panel, poolId, onCancelRequest, isCancelling }) {
  const { drawerState, updateDrawer } = useDrawerState();

  if (!panel) {
    return (
      <div className="selection-panel selection-panel--empty">
        <p className="selection-panel__hint">Select a player or expand a box to see details</p>
      </div>
    );
  }

  if (panel.type === "player") {
    return (
      <div className="selection-panel">
        <div className="selection-panel__header">
          <span className="selection-panel__player-name">{panel.player.name}</span>
          <TeamBadge shortCode={panel.player.current_team_short_code} />
        </div>
        <PlayerDrawer
          player={panel.player}
          isOpen={true}
          onClose={null}
          drawerState={drawerState}
          onDrawerChange={updateDrawer}
          poolId={poolId}
        />
      </div>
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
