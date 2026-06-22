import { Link } from "react-router-dom";
import { useMutation } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";
import { usePool } from "@/context/PoolContext";
import LoadingState from "@c/shared/LoadingState";
import PoolSettingsEditor from "./PoolSettingsEditor";
import { ScoringSection } from "@c/pool/ScoringSection";
import BoxPreview from "@c/boxes/BoxPreview";
import { useLeagueConstants } from "@/constants/useLeagueConstants";

const ReviewSection = ({ title, editPath, children }) => (
  <div className="setup-review__section">
    <div className="setup-review__section-header">
      <h2 className="setup-review__section-title">{title}</h2>
      <Link to={editPath} className="btn-primary btn-sm">Edit</Link>
    </div>
    {children}
  </div>
);

export default function ReviewSetup({
  poolId,
  data,
  onSave,
  saveLabel,
}) {
  const { authHeaders } = useAuth();
  const { pool } = usePool();
  const { rosterTypeLabels } = useLeagueConstants();
  const { scoring, boxes } = data;

  const activateMutation = useMutation({
    mutationFn: async () => {
      const res = await fetch(`/api/commissioner/${poolId}/activate`, {
        method: "PATCH",
        headers: authHeaders,
      });
      if (!res.ok) throw new Error("Failed to activate pool");
    },
  });

  const handleActivateClick = () => onSave(() => activateMutation.mutateAsync());

  return (
    <div className="app-wrapper">
      <p className="setup-page-subtitle">
        Review your pool settings before activating. You can go back and make changes at any time.
      </p>

      <ReviewSection title="Pool Settings" editPath={`/pools/${poolId}/edit`}>
        <PoolSettingsEditor
          poolId={poolId}
          data={pool}
          mode="viewing"
        />
      </ReviewSection>

      
      <ReviewSection title="Scoring" editPath={`/pools/${poolId}/scoring/edit`}>
        {scoring && Object.entries(scoring).map(([rosterType, fields]) => (
          <ScoringSection
            key={rosterType}
            title={rosterTypeLabels[rosterType] ?? rosterType}
            scorings={fields.filter((f) => f.value !== null && f.value !== 0)}
            editable={false}
          />
        ))}
      </ReviewSection>

      <ReviewSection title="Boxes" editPath={`/pools/${poolId}/boxes/edit`}>
        {boxes?.boxes?.map((box) => (
          <BoxPreview key={box.name} box={box} />
        ))}
      </ReviewSection>

      <div className="setup-confirm-bar">
        <p className="setup-confirm-meta">
          {boxes?.boxes?.length ?? 0} boxes · {boxes?.boxes?.reduce((n, b) => n + b.players.length, 0) ?? 0} players assigned
        </p>
        <button
          className="btn-primary"
          onClick={handleActivateClick}
          disabled={activateMutation.isPending}
        >
          {activateMutation.isPending ? "Activating..." : saveLabel}
        </button>
      </div>
    </div>
  );
}
