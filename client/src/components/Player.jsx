import React from 'react'
import { PWHL_TEAMS } from '../constants/teams';

const Player = ({ player, scoreType = 'season_to_date', children }) => {
  const teamInfo = PWHL_TEAMS[player.current_team_id] || PWHL_TEAMS['default'];

  return (
    <div className="player-display-row">
      {children && <div className="player-action">{children}</div>}
      <span className="player-name">{player.name}</span>
      <span className="team-tag" style={{ color: teamInfo.color }}>
        {teamInfo.short}
      </span>

      <div className="player-score-container">
        <span className="score-value">{player.scores[scoreType]}</span>
        <span className="score-label">PTS</span>
      </div>
    </div>
  )
}

export default Player
