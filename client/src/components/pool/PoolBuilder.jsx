import { useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useQueryClient } from "@tanstack/react-query";
import { usePool } from "@/context/PoolContext";
import StepBadge from "@c/shared/StepBadge";
import LoadingState from "@c/shared/LoadingState";
import ScoringEditor from "@c/scoring/ScoringEditor";
import BoxEditor from "@c/boxes/BoxEditor";
import { useScoringIndex } from "@/hooks/useScoring";
import { useBoxesIndex } from "@/hooks/useBoxes";
import PoolReview from "./PoolReview";

const STEPS = [
  {
    key: "scoring",
    label: "Configure Scoring",
    Component: ScoringEditor,
    useStepData: useScoringIndex,
    isComplete: (pool) => pool.pool_scoring_count > 0,
  },
  {
    key: "boxes",
    label: "Configure Boxes",
    Component: BoxEditor,
    useStepData: useBoxesIndex,
    isComplete: (pool) => pool.pool_boxes_count > 0,
  },
  {
    key: "review",
    label: "Review & Activate",
    Component: PoolReview,
    useStepData: () => ({ data: null, isLoading: false, error: null }),
    isComplete: () => false,
  },
];

export default function PoolBuilder() {
  const { poolId } = useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { pool } = usePool();

  useEffect(() => {
    if (pool && pool.state !== "draft") {
      navigate(`/pools/${poolId}`, { replace: true });
    }
  }, [pool, poolId, navigate]);

  const handleCancel = () => navigate("/dashboard");

  if (!pool) return <LoadingState />;

  const rawStep = STEPS.findIndex((s) => !s.isComplete(pool));
  const step = rawStep === -1 ? STEPS.length - 1 : rawStep;
  const current = STEPS[step];

  const { data, isLoading, error } = current.useStepData(poolId);

  if (isLoading || error) return <LoadingState error={error} />;

  const handleSave = (save) => {
    save().then(() => {
      queryClient.removeQueries({ queryKey: ["pool", poolId] });

      if (step === STEPS.length - 1) {
        navigate(`/pools/${poolId}/invite`);
      }
    });
  };

  return (
    <div className="app-wrapper">
      <StepBadge label="New Pool" step={step + 1} total={STEPS.length} />
      <h1 className="setup-page-title">{current.label}</h1>

      <current.Component
        poolId={poolId}
        data={data}
        editable
        onSave={handleSave}
        onCancel={handleCancel}
        saveLabel={step === STEPS.length - 1 ? "Activate Pool →" : "Save & Continue →"}
      />
    </div>
  );
}
