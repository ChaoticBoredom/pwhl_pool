import { useParams, useNavigate } from "react-router-dom";
import { useQueryClient } from "@tanstack/react-query";
import { usePool } from "@/context/PoolContext";
import PoolSettingsEditor from "@c/pool/PoolSettingsEditor";

export default function PoolSettingsConfig() {
  const { poolId } = useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { pool } = usePool();

  const handleSave = (save) => {
    save().then(() => {
      queryClient.invalidateQueries({ queryKey: ["pool", poolId] });
      navigate(`/pools/${poolId}`);
    });
  };

  return (
    <div className="app-wrapper">
      <h1 className="setup-page-title">Pool Settings</h1>

      <PoolSettingsEditor
        poolId={poolId}
        data={pool}
        mode="editing"
        onSave={handleSave}
        onCancel={() => navigate(-1)}
        saveLabel="Save Settings"
      />
    </div>
  );
}
