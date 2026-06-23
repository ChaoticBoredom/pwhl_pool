import { useContext } from "react";
import { useQuery } from "@tanstack/react-query";
import { useParams, Link } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import PoolContext from "@/context/PoolContext";
import { DataRow } from "@c/shared/DataRow";
import { formatDate } from "@/utils/formatDate";

export default function PoolDetails() {
  const { poolId } = useParams();
  const { authHeaders, currentUser } = useAuth();
  const { pool, isCommissioner } = useContext(PoolContext);
  const poolGrid = "grid-cols-[40px_1fr_160px_80px]";

  const { dataUpdatedAt } = useQuery({
    queryKey: ["pool", poolId],
    queryFn: () => fetch(`/api/pools/${poolId}`, { headers: authHeaders }).then((r) => r.json()),
    staleTime: 25_000,
    refetchInterval: (query) => { return query.state.data?.games_active ? 30_000 : false; },
    gcTime: 5 * 60 * 1000, // 5 minutes to store cached data
  });

  const toOrdinal = (i) => {
    if (isNaN(i)) return;
    const j = i % 10, k = i % 100;
    if (j === 1 && k !== 11) return i + "st";
    if (j === 2 && k !== 12) return i + "nd";
    if (j === 3 && k !== 13) return i + "rd";
    return i + "th";
  };

  if (!pool) return <div>Loading pool details...</div>;

  const lastFetchedAt = formatDate(dataUpdatedAt);
  const hasOwnTeam = pool.pool_teams?.some((team) => team.user?.id === currentUser);

  return (
    <div>
      <p className="helper-text">Commissioner: {pool.admin.name}</p>
      <p className="helper-text">Last Updated At: {lastFetchedAt}</p>

      {pool.state !== "active" && (
        <Link to={`/pools/${poolId}/setup`} className="btn-primary btn-top">
          Continue Setup →
        </Link>
      )}

      {pool.state === "active" && isCommissioner && !hasOwnTeam && (
        <Link to={`/pools/${poolId}/invite`} className="btn-primary btn-top">
          Create Team
        </Link>
      )}

      <div className="pool-standings">
        <DataRow isHeader gridClass={poolGrid}>
          <div />
          <div>Team</div>
          <div className="score-cell">Owner</div>
          <div className="score-cell">Score</div>
        </DataRow>

        {pool.pool_teams?.sort((a, b) => a.rank - b.rank)?.map((team) => (
          <DataRow key={team.id} to={`/pools/${poolId}/teams/${team.id}`} gridClass={poolGrid}>
            <div className="pool-rank">{toOrdinal(team.rank)}</div>
            <div className="pool-team-name">{team.team_name}</div>
            <div className="pool-owner-name">{team.user?.name}</div>
            <div className="score-cell font-bold">{team.total_score.toFixed(2)}</div>
          </DataRow>
        ))}
      </div>
    </div>
  );
};
