import React from 'react'
import TeamBadge from "./TeamBadge";
import { PWHL_TEAMS } from '../constants/teams';

const Player = ({ player, children }) => {
  const teamInfo = PWHL_TEAMS[player.current_team_short_code] || PWHL_TEAMS['default'];

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
