import { useParams, useNavigate, Link } from "react-router-dom";
import { useQuery, useMutation } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";
import { usePool } from "@/context/PoolContext";
import useNotices from "@/hooks/useNotices";
import LoadingState from "@c/shared/LoadingState";
import StepBadge from "@c/shared/StepBadge";
import { ScoringSection } from "@c/pool/ScoringSection";
import { DraftBox } from "@c/boxes/BoxDraft";
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

const ReviewField = ({ label, value }) => (
  <div className="setup-review__field">
    <span className="setup-review__label">{label}</span>
    <span className="setup-review__value">{value}</span>
  </div>
);

export default function ReviewSetup() {
  const { poolId } = useParams();
  const navigate = useNavigate();
  const { authHeaders } = useAuth();
  const { pool } = usePool();
  const { add } = useNotices();
  const { rosterTypeLabels } = useLeagueConstants();

  const { data: meta } = useQuery({
    queryKey: ["pools-meta"],
    queryFn: async () => {
      const res = await fetch("/api/pools/meta", { headers: authHeaders });
      if (!res.ok) throw new Error("Failed to load meta");
      return res.json();
    },
    staleTime: Infinity,
  });

  const { data: scoring, isLoading: scoringLoading } = useQuery({
    queryKey: ["pool-scoring", poolId],
    queryFn: async () => {
      const res = await fetch(`/api/pools/${poolId}/pool_scoring`, {
        headers: authHeaders,
      });
      if (!res.ok) throw new Error("Failed to load scoring");
      return res.json();
    },
    staleTime: Infinity,
  });

  const { data: boxes, isLoading: boxesLoading } = useQuery({
    queryKey: ["commissioner-pool-boxes", poolId],
    queryFn: async () => {
      const res = await fetch(`/api/commissioner/${poolId}/pool_boxes`, {
        headers: authHeaders,
      });
      if (!res.ok) throw new Error("Failed to load boxes");
      return res.json();
    },
    staleTime: Infinity,
  });

  const activateMutation = useMutation({
    mutationFn: async () => {
      const res = await fetch(`/api/commissioner/${poolId}/activate`, {
        method: "PATCH",
        headers: authHeaders,
      });
      if (!res.ok) throw new Error("Failed to activate pool");
    },
    onSuccess: () => {
      add({ severity: "success", message: "Pool activated! Share the invite link to get started." });
      navigate(`/pools/${poolId}`);
    },
    onError: (err) => {
      add({ severity: "error", message: err.message });
    },
  });

  const seasonLabel = (id) =>
    meta?.seasons?.find((s) => s.id === id)?.name ?? id;

  const tradePolicyLabel = (policy) =>
    policy?.replace(/_/g, " ");

  if (scoringLoading || boxesLoading) return <LoadingState message="Loading review…" />;

  return (
    <div className="app-wrapper">
      <StepBadge label="New Pool" step={4} total={4} />
      <h1 className="setup-page-title">Review & Activate</h1>
      <p className="setup-page-subtitle">
        Review your pool settings before activating. You can go back and make changes at any time.
      </p>

      <ReviewSection title="Pool Settings" editPath={`/pools/${poolId}/edit`}>
        <div className="setup-review__fields">
          <ReviewField label="Name" value={pool.name} />
          <ReviewField label="Season" value={seasonLabel(pool.season_id)} />
          {pool.reference_season_id && (
            <ReviewField label="Reference Season" value={seasonLabel(pool.reference_season_id)} />
          )}
          <ReviewField label="Trade Policy" value={tradePolicyLabel(pool.trade_policy)} />
        </div>
      </ReviewSection>

      
      <ReviewSection title="Scoring" editPath={`/pools/${poolId}/scoring/edit`}>
        {scoring && Object.entries(scoring).map(([rosterType, fields]) => (
          <ScoringSection
            key={rosterType}
            title={rosterTypeLabels[rosterType] ?? rosterType}
            scorings={fields.filter((f) => f.value !== null && f.value !== 0)}
            editable={false}
            onChange={() => {}}
          />
        ))}
      </ReviewSection>

      <ReviewSection title="Boxes" editPath={`/pools/${poolId}/boxes/edit`}>
        {boxes?.boxes?.map((box) => (
          <DraftBox key={box.name} box={box} />
        ))}
      </ReviewSection>

      <div className="setup-confirm-bar">
        <p className="setup-confirm-meta">
          {boxes?.boxes?.length ?? 0} boxes · {boxes?.boxes?.reduce((n, b) => n + b.players.length, 0) ?? 0} players assigned
        </p>
        <button
          className="btn-primary"
          onClick={() => activateMutation.mutate()}
          disabled={activateMutation.isPending}
        >
          {activateMutation.isPending ? "Activating…" : "Activate Pool →"}
        </button>
      </div>
    </div>
  );
}
