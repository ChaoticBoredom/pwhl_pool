import { Link } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";

export function Dashboard() {
  const { authHeaders } = useAuth();

  const { data: pools = [] } = useQuery({
    queryKey: ["pools"],
    queryFn: async () => {
      const res = await fetch("/api/pools", { headers: authHeaders });
      if (!res.ok) throw new Error("Failed to load pools");
      return res.json();
    },
    staleTime: 30 * 1000,
  });

  return (
    <div className="app-wrapper">
      <div className="selection-header">
        <h1 className="page-title">Your Pools</h1>
        <Link to="/pools/new" className="btn-primary btn-top">
          + New Pool
        </Link>
      </div>

      <div className="player-list">
        {pools.map((pool) => (
          <Link
            key={pool.id}
            to={`/pools/${pool.id}`}
            className="player-option"
          >
            <div className="player-display-row">
              <div className="player-identity-vertical">
                <span className="player-name">{pool.name}</span>
                <span className="team-badge" style={{
                  background: pool.is_admin ? "var(--accent-bg)" : "var(--card-bg)",
                  color: pool.is_admin ? "var(--accent)" : "var(--text-muted)",
                }}>
                  {pool.is_admin ? "Commissioner" : "Member"}
                </span>
              </div>
              <span className="score-display-vertical">
                <span className="score-label">{pool.state}</span>
                <span className="score-label">{pool.season_label}</span>
              </span>
            </div>
          </Link>
        ))}
      </div>
    </div>
  );
}
