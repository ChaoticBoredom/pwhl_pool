import { useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useQuery, useMutation } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";
import useNotices from "@/hooks/useNotices";
import { boxBadgeClass, boxBadgeLabel } from "@/utils/boxConfig";

function BoxPreview({ box }) {
  const [open, setOpen] = useState(false);
  const preview = box.players.map((p) => p.team_short_code).join(" · ");

  return (
    <div className="result-box">
      <button className="result-box-header" onClick={() => setOpen((o) => !o)}>
        <span className={`box-badge ${boxBadgeClass(box.name)}`}>
          {boxBadgeLabel(box.name)}
        </span>
        <span className="result-box-title-group">
          <span className="result-box-name">{box.name}</span>
          <span className="result-box-preview">{preview}</span>
        </span>
        <span className="result-box-count">{box.players.length} players</span>
      </button>

      {open && (
        <div className="result-box-players">
          {box.players.map((player) => (
            <div key={player.id} className="setup-player-row">
              <span className="player-name">{player.name}</span>
              <span
                className="team-badge"
                style={{ background: "var(--accent-bg)", color: "var(--accent)" }}
              >
                {player.team_short_code}
              </span>
              <span className="setup-player-score">{player.score.toFixed(2)}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export default function SetupPool() {
  const { poolId } = useParams();
  const navigate = useNavigate();
  const { authHeaders } = useAuth();
  const { add } = useNotices();

  const { data, isLoading, error } = useQuery({
    queryKey: ["pool-boxes-generate", poolId],
    queryFn: async () => {
      const res = await fetch(`/api/commissioner/${poolId}/pool_boxes/default`, {
        headers: authHeaders,
      });
      if (!res.ok) throw new Error("Failed to generate default boxes");
      return res.json();
    },
    staleTime: Infinity,
  });

  const confirmMutation = useMutation({
    mutationFn: async () => {
      const boxesRes = await fetch(`/api/commissioner/${poolId}/pool_boxes`, {
        method: "POST",
        headers: authHeaders,
        body: JSON.stringify({
          boxes: data.boxes.map((box, i) => ({
            name: box.name,
            position: i + 1,
            players: box.players.map((p) => ({ id: p.id })),
          })),
        }),
      });

      if (!boxesRes.ok) {
        const err = await boxesRes.json();
        throw new Error(err.errors?.join(", ") || "Failed to save boxes");
      }

      const activateRes = await fetch(`/api/commissioner/${poolId}/activate`, {
        method: "PATCH",
        headers: authHeaders,
      });

      if (!activateRes.ok) {
        const err = await activateRes.json();
        throw new Error(err.error || "Failed to activate pool");
      }
    },
    onSuccess: () => {
      add({ severity: "success", message: "Pool created and activated!" });
      navigate(`/pools/${poolId}`);
    },
    onError: (err) => {
      add({ severity: "error", message: err.message });
    },
  });

  const totalPlayers = data?.boxes?.reduce((n, b) => n + b.players.length, 0) ?? 0;

  return (
    <div className="app-wrapper">
      <div className="setup-step-badge">New Pool — Step 2 of 2</div>
      <h1 className="setup-page-title">Review Default Boxes</h1>
      <p className="setup-page-subtitle">
        These are your pool's default player boxes based on last season's rankings.
        You can adjust them later when I build that part.
      </p>

      {isLoading && <p className="report-loading">Generating boxes…</p>}
      {error && <p className="report-error">{error.message}</p>}

      {data && (
        <>
          <div className="result-box-list">
            {data.boxes.map((box) => (
              <BoxPreview key={box.name} box={box} />
            ))}
          </div>

          <div className="setup-confirm-bar">
            <p className="setup-confirm-meta">
              {data.boxes.length} boxes · {totalPlayers} players total
            </p>
            <button
              className="btn-primary"
              onClick={() => confirmMutation.mutate()}
              disabled={confirmMutation.isPending}
            >
              {confirmMutation.isPending ? "Activating…" : "Confirm & Activate Pool →"}
            </button>
          </div>
        </>
      )}
    </div>
  );
}
