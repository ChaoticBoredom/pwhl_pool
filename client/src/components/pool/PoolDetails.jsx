import { useContext } from "react";
import { useQuery } from "@tanstack/react-query";
import { useParams, Link } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import PoolContext from "@/context/PoolContext";
import { DataRow } from "@c/shared/DataRow";
import { formatDate } from "@/utils/formatDate";

const poolColumns = [
  { width: "40px" },
  { width: "1fr" },
  { width: "80px" },
];

export default function PoolDetails() {
  const { poolId } = useParams();
  const { authHeaders, currentUser } = useAuth();
  const { pool } = useContext(PoolContext);

  const { dataUpdatedAt } = useQuery({
    queryKey: ["pool", poolId],
    queryFn: () => fetch(`/api/pools/${poolId}`, { headers: authHeaders }).then((r) => r.json()),
    staleTime: 25_000,
    refetchInterval: (query) => { return query.state.data?.games_active ? 30_000 : false; },
    gcTime: 5 * 60 * 1000,
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

      {pool.state === "draft" && (
        <Link to={`/pools/${poolId}/setup`} className="btn-primary btn-top">
          Continue Setup →
        </Link>
      )}

      {pool.state === "active" && !hasOwnTeam && (
        <Link to={`/pools/${poolId}/invite`} className="btn-primary btn-top">
          Create Team
        </Link>
      )}

      <div className="pool-standings">
        <DataRow columns={poolColumns} isHeader>
          <div />
          <div>Team</div>
          <div className="score-cell">Score</div>
        </DataRow>

        {pool.pool_teams?.sort((a, b) => a.rank - b.rank)?.map((team) => (
          <DataRow key={team.id} to={`/pools/${poolId}/teams/${team.id}`} columns={poolColumns}>
            <div className="pool-rank">{toOrdinal(team.rank)}</div>
            <div className="pool-team-cell">
              <span className="pool-team-name">{team.team_name}</span>
              <span className="pool-team-owner">{team.user?.name}</span>
            </div>
            <div className="score-cell stat-value stat-value--bold">{team.total_score.toFixed(2)}</div>
          </DataRow>
        ))}
      </div>
    </div>
  );
}
