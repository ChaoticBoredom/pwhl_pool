import { useNavigate } from "react-router-dom";
import PoolSettingsEditor from "@c/pool/PoolSettingsEditor";

export default function CreatePool() {
  const navigate = useNavigate();

  const handleSave = (save) => {
    save().then((createdPool) => {
      navigate(`/pools/${createdPool.id}/setup`);
    });
  };

  return (
    <div className="create-pool-page">
      <div className="create-pool-form panel">
        <h2>Create Pool</h2>
        <p className="setup-page-subtitle">
          Set up the basics. You'll setup scoring next.
        </p>

        <PoolSettingsEditor
          mode="creating"
          onSave={handleSave}
          onCancel={() => navigate("/")}
          saveLabel="Continue to Scoring Setup →"
        />
      </div>
    </div>
  );
}
