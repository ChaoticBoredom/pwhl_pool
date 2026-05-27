import { PWHL_TEAMS } from "../constants/teams";

const TeamBadge = ({ shortCode }) => {
  const teamInfo = PWHL_TEAMS[shortCode] || PWHL_TEAMS["default"];
  console.log(shortCode)
  console.log(teamInfo)

  return (
    <span
      className="team-badge"
      style={{
        backgroundColor: teamInfo.bg,
        color: teamInfo.text,
      }}
    >
      {shortCode}
    </span>
  );
};

export default TeamBadge;
