import { useParams, useNavigate } from "react-router-dom";
import { useQueryClient } from "@tanstack/react-query";
import { useScoringIndex } from "@/hooks/useScoring";
import ScoringEditor from "./ScoringEditor";
import LoadingState from "@c/shared/LoadingState";

export default function ScoringConfig() {
  const { poolId } = useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { data, isLoading, error } = useScoringIndex(poolId);

  if (isLoading || error) return <LoadingState error={error} />;

  const handleSave = (save) => {
    save().then(() => {
      queryClient.removeQueries({ queryKey: ["pool-scoring", poolId] });
      navigate(`/pools/${poolId}/scoring`);
    });
  };

  const handleCancel = () => navigate(`/pools/${poolId}/scoring`);

  return (
    <div className="app-wrapper">
      <h1 className="scoring-page-title">Configure Scoring</h1>

      <ScoringEditor
        poolId={poolId}
        data={data}
        editable
        onSave={handleSave}
        onCancel={handleCancel}
        saveLabel="Save Scoring"
      />
    </div>
  );
}
