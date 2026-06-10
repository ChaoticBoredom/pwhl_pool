import { usePool } from "@/context/PoolContext";
import { getLeagueConstants } from "@/constants";

const TeamBadge = ({ shortCode }) => {
  const { pool } = usePool();
  const { teams } = getLeagueConstants(pool?.league?.short_name);
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
