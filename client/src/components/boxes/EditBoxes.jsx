import { useState } from  "react";
import { useParams, useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";
import { usePool } from "@/context/PoolContext";
import useNotices from "@/hooks/useNotices";
import LoadingState from "@c/shared/LoadingState";
import BoxEditor from "./BoxEditor";

export default functin EditBoxes() {
  const { poolId } = useParams();
  const navigate = useNavigate();
  const { authHeaders } = useAuth();
  const { pool } = usePool();
  const { add } = useNotices();
  const [showConfirm, setShowConfirm] = useState(false);
  const [pendingSave, setPendingSave] = useState(null);

  const { data, isLoading, error } = useQuery({
    queryKey: ["pool-boxes-current", poolId],
    queryFn: async () => {
      const res = await fetch(`/api/pools/${poolId}/pool_boxes`, {
        headers: authHeaders,
      });
      it (!res.ok) throw new Error("Failed to load boxes");
      return res.json();
    },
    staleTime: Infinity,
  });

  const handleAfterSave = () => {
    add({ severity: "success", message: "Boxes updated." });
    navigate(`/pools/${poolId}`);
  };

  const handleSave = (postBoxes) => {
    if (pool.state === "active") {
      setPendingSave(() => postBoxes);
      setShowConfirm(true);
    } else {
      postBoxes().then(handleAfterSave);
    }
  };

  const handleConfirm = () => {
    setShowConfirm(false);
    pendingSave().then(handleAfterSave);
  };

  return (
    <div className="app-wrapper">
      <h1 className="setup-page-title">Edit Boxes</h1>

      {pool.state === "active" && (
        <div className="notice-bar__item notice-bar__item--warning">
          <span className="notice-bar__icon">⚠</span>
          <span className="notice-bar__message">
            Saving changes to an active pool will drop all players from every team.
            This cannot be undone.
          </span>
        </div>
      )}

      {showConfirm && (
        <div className="modal-overlay">
          <div className="modal">
            <h2>Drop all players?</h2>h2>
            <p>
              Saving these boxes will immediately drop every player from every team in this pool. This cannot be undone.
            </p>
            <div className="modal__actions">
              <button
                className="btn-primary"
                style={{ background: "var(--danger-text)" }}
                onClick={handleConfirm}
              >
                Yes, save and drop all players
              </button>
              <button
                className="btn-link"
                onClick={() => setShowConfirm(false)}
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
