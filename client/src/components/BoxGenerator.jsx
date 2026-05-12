import { useState } from "react";
import { useParams } from "react-router-dom";
import BoxGeneratorForm from "./BoxGeneratorForm";
import BoxDraft from "./BoxDraft";

const BoxGenerator = () => {
  const { poolId } = useParams();
  const [draft, setDraft] = useState(null);

  return (
    <div className="selection-container">
      <header className="selection-header">
        <h2 className="page-title">Box Generator</h2>
      </header>

      <BoxGeneratorForm poolId={poolId} onGenerated={setDraft} />

      {draft && (
        <BoxDraft
          boxes={draft.boxes || []}
          usingReferenceSeason={draft.using_reference_season}
          onSave={null}
        />
      )}
    </div>
  );
};

export default BoxGenerator;
