import { useLeagueConstants } from "@/constants/useLeagueConstants";

const TeamBadge = ({ shortCode }) => {
  const { teams } = useLeagueConstants();
  const teamInfo = teams[shortCode] || teams["default"];

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
