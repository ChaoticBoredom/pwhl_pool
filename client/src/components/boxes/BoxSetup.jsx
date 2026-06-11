import { useParams, useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";
import useNotices from "@/hooks/useNotices";
import LoadingState from "@c/shared/LoadingState";
import BoxEditor from "./BoxEditor";

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

      {(isLoading || error)
        ? <LoadingState error={error} message="Generating boxes…" />
        : data && (
            <BoxEditor
              poolId={poolId}
              initialBoxes={data.boxes}
              initialFreeAgents={data.free_agents}
              onSave={(postBoxes) => postBoxes().then(handleAfterSave)}
              saveLabel="Confirm & Activate Pool →"
            />
          )
      }
    </div>
  );
}
