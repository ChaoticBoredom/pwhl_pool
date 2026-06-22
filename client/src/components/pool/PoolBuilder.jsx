import { useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useQueryClient } from "@tanstack/react-query";
import { usePool } from "@/context/PoolContext";
import StepBadge from "@c/shared/StepBadge";
import LoadingState from "@c/shared/LoadingState";
import ScoringEditor from "@c/pool/ScoringEditor";
import BoxEditor from "@c/boxes/BoxEditor";
import { useScoringIndex } from "@/hooks/useScoring";
import { useBoxesDefault, useBoxesIndex } from "@/hooks/useBoxes";
import ReviewSetup from "./ReviewSetup";
import useNotices from "@/hooks/useNotices";

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
  const { add } = useNotices();

  const rawStep = pool ? STEPS.findIndex((s) => !s.isComplete(pool)) : null;
  const step = rawStep === null ? null : (rawStep === -1 ? STEPS.length - 1 : rawStep);

  // Fetch scoring data on step 0, and step 2 (ScoringSetup and Review)
  const scoringStepData = useScoringIndex(poolId, { enabled: [0, 2].includes(step) });
  // Fetch default boxes on step 1
  const boxesStepData = useBoxesDefault(poolId, { enabled: step === 1 });
  // Fetch created boxes on step 2
  const boxesReviewData = useBoxesIndex(poolId, { enabled: step === 2 });
  const reviewStepData = {
    data: {scoring: scoringStepData.data, boxes: boxesReviewData.data },
    isLoading: scoringStepData.isLoading || boxesReviewData.isLoading,
    error: scoringStepData.error || boxesReviewData.error,
  };

  useEffect(() => {
    if (pool && pool.state !== "draft") {
      navigate(`/pools/${poolId}/invite`, { replace: true });
    }
  }, [pool, poolId, navigate]);

  const handleCancel = () => navigate("/dashboard");

  if (!pool) return <LoadingState />;

  const current = STEPS[step];
  const allStepData = [scoringStepData, boxesStepData, reviewStepData];
  const { data, isLoading, error } = allStepData[step];

  if (isLoading || error) return <LoadingState error={error} />;

  const handleSave = (save) => {
    save().then(async () => {
      await queryClient.refetchQueries({ queryKey: ["pool", poolId] });

      if (step === STEPS.length - 1) {
        add({ severity: "success", message: "Pool activated! Share the invite link to get started."});
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
