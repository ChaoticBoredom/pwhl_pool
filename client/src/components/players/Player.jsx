import React from "react";
import TeamBadge from "@c/shared/TeamBadge";

const Player = ({ player, badges, children }) => {
  return (
    <div className="player-row-container flex items-left gap-3">
      {children && <div className="player-action">{children}</div>}

      <div className="player-identity-vertical">
        <span className="player-name">{player.name}</span>
        <div className="player-meta">
          <TeamBadge shortCode={player.current_team_short_code} />
          {player.position && (
            <span className="badge badge--neutral">{player.position}</span>
          )}
          {player.rookie && (
            <span className="player-rookie-star" title="Rookie">★</span>
          )}
        </div>
        {badges && <div className="player-pending-badges">{badges}</div>}
      </div>
    </div>
  );
};

export default Player;
