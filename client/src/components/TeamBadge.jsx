import React from 'react'
import { PWHL_TEAMS } from '../constants/teams';

const TeamBadge = ({ short_code }) => {
  const teamInfo = PWHL_TEAMS[short_code] || PWHL_TEAMS['default'];

  console.log(short_code, teamInfo)

  return (
    <span className="team-badge-small" style={{ color: teamInfo.color }}>
      {short_code}
    </span>
  );
}

export default TeamBadge
