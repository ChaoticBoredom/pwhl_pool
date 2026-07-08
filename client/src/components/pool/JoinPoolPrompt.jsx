import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useMutation } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";
import { usePool } from "@/context/PoolContext";
import useNotices from "@/hooks/useNotices";
import LoadingState from "@c/shared/LoadingState";

export default function JoinPoolPrompt() {
  const { poolId } = useParams();
  const navigate = useNavigate();
  const { currentUser, authHeaders } = useAuth();
  const { pool } = usePool();
  const { add } = useNotices();
  const [teamName, setTeamName] = useState("");

  const existingTeam = pool?.pool_teams?.find((team) => team.user.id === currentUser);
  const hasTeam = Boolean(existingTeam);

  useEffect(() => {
    if (hasTeam) navigate(`/pools/${poolId}/teams/${existingTeam.id}`);
  }, [hasTeam, existingTeam, navigate, poolId]);

  const joinMutation = useMutation({
    mutationFn: async () => {
      const res = await fetch("/api/pool_teams", {
        method: "POST",
        headers: authHeaders,
        body: JSON.stringify({
          team: {
            team_name: teamName,
            pool_id: poolId,
          },
        }),
      });
      if (!res.ok) throw new Error("Failed to create team");
      return res.json();
    },
    onSuccess: (result) => {
      navigate(`/pools/${poolId}/teams/${result.data.id}/select`);
    },
    onError: (err) => {
      add({ severity: "error", message: err.message });
    },
  });

  const handleJoin = (e) => {
    e.preventDefault();
    joinMutation.mutate();
  };

  const getButtonText = () => {
    if (hasTeam) return "Redirecting to your team...";
    if (joinMutation.isPending) return "Creating...";
    return "Create Team & Pick Players";
  };

  if (!pool) return <LoadingState message="Loading pool details..." />;

  return (
    <div className="panel auth-card">
      <p>
        You're joining:
      </p>
      <h2>{pool.name}</h2>

      <form onSubmit={handleJoin} className="stack">
        <div className="form-field">
          <label htmlFor="teamName" className="label-eyebrow label-eyebrow--md">Team Name</label>
          <input
            id="teamName"
            type="text"
            className="form-input"
            placeholder="Enter your team name..."
            value={teamName}
            onChange={(e) => setTeamName(e.target.value)}
            required
            autoFocus
          />
        </div>
        <button type="submit" className="btn-primary" disabled={joinMutation.isPending || hasTeam}>
          {getButtonText()}
        </button>
      </form>
    </div>
  );
}
