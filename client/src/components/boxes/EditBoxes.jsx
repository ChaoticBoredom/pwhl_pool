import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";
import { usePool } from "@/context/PoolContext";
import useNotices from "@/hooks/useNotices";
import LoadingState from "@c/shared/LoadingState";
import BoxEditor from "./BoxEditor";

export default function EditBoxes() {
  const { poolId } = useParams();
  const navigate = useNavigate();
  const { authHeaders } = useAuth();
  const { pool } = usePool();
  const { add } = useNotices();
  const [confirmId, setConfirmId] = useState(null);

  useEffect(() => {
    if (pool.state === "completed") {
      navigate(`/pools/${poolId}`, { replace: true });
    }
  }, [pool.state, poolId, navigate]);

  const { data, isLoading, error } = useQuery({
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

  const handleAfterSave = () => {
    add({ severity: "success", message: "Boxes updated." });
    navigate(`/pools/${poolId}`);
  };

  const handleSave = (postBoxes) => {
    if (pool.state !== "active") {
      postBoxes().then(handleAfterSave);
      return;
    }

    if (confirmId !== null) return;

    const id = add({
      severity: "action",
      dismissable: false,
      message: "Saving will drop all players from every team in this pool. This cannot be undone.",
      actions: [
        {
          label: "Save and drop all players",
          onClick: () => {
            setConfirmId(null);
            postBoxes().then(handleAfterSave);
          },
        },
        {
          label: "Cancel",
          variant: "secondary",
          onClick: () => setConfirmId(null),
        },
      ],
    });

    setConfirmId(id);
  };

  return (
    <div className="app-wrapper">
      <h1 className="setup-page-title">Edit Boxes</h1>

      {(isLoading || error)
        ? <LoadingState error={error} message="Loading boxes…" />
        : data && (
            <BoxEditor
              poolId={poolId}
              initialBoxes={data.boxes}
              initialFreeAgents={data.free_agents}
              onSave={handleSave}
              saveLabel="Save Boxes"
            />
          )
      }
    </div>
  );
}
