import { useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useQueryClient } from "@tanstack/react-query";
import { usePool } from "@/context/PoolContext";
import StepBadge from "@c/shared/StepBadge";
import LoadingState from "@c/shared/LoadingState";
import ScoringEditor from "@c/pool/ScoringEditor";
import BoxEditor from "@c/boxes/BoxEditor";
import { useScoringIndex } from "@/hooks/useScoring";
import { useBoxesDefault } from "@/hooks/useBoxes";
import ReviewSetup from "./ReviewSetup";

const STEPS = [
  {
    key: "scoring",
    label: "Configure Scoring",
    Component: ScoringEditor,
    isComplete: (pool) => pool.pool_scoring_count > 0,
  },
  {
    key: "boxes",
    label: "Configure Boxes",
    Component: BoxEditor,
    isComplete: (pool) => pool.pool_boxes_count > 0,
  },
  {
    key: "review",
    label: "Review & Activate",
    Component: ReviewSetup,
    isComplete: () => false,
  },
];


export default function PoolBuilder() {
  const { poolId } = useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { pool } = usePool();

  const rawStep = pool ? STEPS.findIndex((s) => !s.isComplete(pool)) : -1;
  const step = rawStep === -1 ? STEPS.length - 1 : rawStep;

  const scoringStepData = useScoringIndex(poolId, { enabled: step === 0 });
  const boxesStepData = useBoxesDefault(poolId, { enabled: step === 1 });
  const reviewStepData = { data: null, isLoading: false, error: null };

  useEffect(() => {
    if (pool && pool.state !== "draft") {
      navigate(`/pools/${poolId}`, { replace: true });
    }
  }, [pool, poolId, navigate]);

  const handleCancel = () => navigate("/dashboard");

  if (!pool) return <LoadingState />;

  const current = STEPS[step];
  const allStepData = [scoringStepData, boxesStepData, reviewStepData];
  const { data, isLoading, error } = allStepData[step];

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
