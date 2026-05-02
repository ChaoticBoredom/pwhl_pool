import React from 'react'
import TeamBadge from "./TeamBadge";

const Player = ({ player, children }) => {
  return (
    <div className="player-row-container flex items-left gap-3">
      {children && <div className="player-action">{children}</div>}

      <div className="player-identity-vertical">
        <span className="player-name">{player.name}</span>
        <TeamBadge short_code={player.current_team_short_code} />
      </div>
    </div>
  )
}

export default Player
