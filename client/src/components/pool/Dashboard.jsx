import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";

function setupPath(pool) {
  if (pool.scoring_count === 0) return `/pools/${pool.id}/scoring/setup`;
  if (pool.box_count === 0) return `/pools/${pool.id}/boxes/setup`;
  return `/pools/${pool.id}/setup`;
}

export function Dashboard() {
  const { authHeaders } = useAuth();
  const [copiedId, setCopiedId] = useState(null);

  const { data: pools = [] } = useQuery({
    queryKey: ["pools"],
    queryFn: async () => {
      const res = await fetch("/api/pools", { headers: authHeaders });
      if (!res.ok) throw new Error("Failed to load pools");
      return res.json();
    },
    staleTime: 30 * 1000,
  });

  const handleCopyInvite = (e, poolId) => {
    e.preventDefault();
    e.stopPropagation();
    navigator.clipboard.writeText(`${window.location.origin}/pools/${poolId}/invite`);
    setCopiedId(poolId);
    setTimeout(() => setCopiedId(null), 2000);
  };

  const navigate = useNavigate();

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
          <div
            key={pool.id}
            className="player-option"
            onClick={() => navigate(`/pools/${pool.id}`)}
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
              <div className="score-display-vertical">
                <span className="score-label">{pool.state}</span>
                <span className="score-label">{pool.season_label}</span>
                {pool.is_admin && pool.state === "draft" && (
                  <Link
                    to={setupPath(pool)}
                    className="btn-primary btn-sm"
                    onClick={(e) => e.stopPropagation()}
                  >
                    Continue Setup →
                  </Link>
                )}
                {pool.is_admin && pool.state === "active" && (
                  <button
                    className="btn-primary btn-sm"
                    onClick={(e) => handleCopyInvite(e, pool.id)}
                  >
                    {copiedId === pool.id ? "Copied!" : "Copy Invite Link"}
                  </button>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
