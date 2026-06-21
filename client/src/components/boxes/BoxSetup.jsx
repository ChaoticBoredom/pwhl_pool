import { useParams, useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";
import LoadingState from "@c/shared/LoadingState";
import StepBadge from "@c/shared/StepBadge";
import BoxEditor from "./BoxEditor";

export default function SetupPool() {
  const { poolId } = useParams();
  const navigate = useNavigate();
  const { authHeaders } = useAuth();

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
    navigate(`/pools/${poolId}/setup`);
  };

  return (
    <div className="app-wrapper">
      <StepBadge label="New Pool" step={3} total={4} /> 
      <h1 className="setup-page-title">Review Default Boxes</h1>
      <p className="setup-page-subtitle">
        These are your pool's default player boxes based on last season's rankings.
        You can adjust them using the drag and drop editor below.
      </p>

      {(isLoading || error)
        ? <LoadingState error={error} message="Generating boxes..." />
        : data && (
            <BoxEditor
              poolId={poolId}
              data={data}
              onSave={(postBoxes) => postBoxes().then(handleAfterSave)}
              saveLabel="Save & Continue →"
            />
          )
      }
    </div>
  );
}
