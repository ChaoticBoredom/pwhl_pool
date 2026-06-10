import { useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";
import useNotices from "@/hooks/useNotices";
import { boxBadgeClass, boxBadgeLabel } from "@/utils/boxConfig";
import BoxEditor from "./BoxEditor";

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

  const handleAfterSave = async () => {
    const res = await fetch(`/api/commissioner/${poolId}/activate`, {
      method: "PATCH",
      headers: authHeaders,
    });
    if (!res.ok) throw new Error("Failed to activate pool");
    add({ severity: "success", message: "Pool activated!" });
    navigate(`/pools/${poolId}`);
  };

  return (
    <div className="app-wrapper">
      <div className="setup-step-badge">New Pool — Step 2 of 2</div>
      <h1 className="setup-page-title">Review Default Boxes</h1>
      <p className="setup-page-subtitle">
        These are your pool's default player boxes based on last season's rankings.
        You can adjust them using the drag and drop editor below.
      </p>

      {isLoading && <p className="report-loading">Generating boxes…</p>}
      {error && <p className="report-error">{error.message}</p>}

      {data && (
        <BoxEditor
          poolId={poolId}
          initialBoxes={data.boxes}
          initialFreeAgents={data.free_agents}
          onSave={(postBoxes) => postBoxes().then(handleAfterSave)}
          saveLabel="Confirm & Activate Pool →"
        />
      )}
    </div>
  );
}
