import { PWHL_TEAMS } from "../constants/teams";

const TeamBadge = ({ short_code }) => {
  const teamInfo = PWHL_TEAMS[short_code] || PWHL_TEAMS["default"];

  return (
    <span
      className="team-badge"
      style={{
        backgroundColor: teamInfo.bg,
        color: teamInfo.text,
      }}
    >
      {short_code}
    </span>
  );
};

export default TeamBadge;
