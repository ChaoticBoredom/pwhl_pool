import React from "react";
import TeamBadge from "@c/shared/TeamBadge";

const Player = ({ player, children }) => {
  return (
    <div className="player-row-container flex items-left gap-3">
      {children && <div className="player-action">{children}</div>}

      <div className="player-identity-vertical">
        <span className="player-name">{player.name}</span>
        <div className="player-meta">
          <TeamBadge shortCode={player.current_team_short_code} />
          {player.position && (
            <span className="player-position-badge">{player.position}</span>
          )}
          {player.rookie && (
            <span className="player-rookie-star" title="Rookie">★</span>
          )}
        </div>
      </div>
    </div>
  );
};

export default Player;
