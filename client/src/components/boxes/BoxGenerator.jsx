import { useState } from "react";
import { useParams } from "react-router-dom";
import BoxGeneratorForm from "./BoxGeneratorForm";
import BoxPreview from "./BoxPreview";

export default function BoxGenerator() {
  const { poolId } = useParams();
  const [draft, setDraft] = useState(null);

  return (
    <div className="selection-container">
      <header className="selection-header">
        <h2 className="page-title">Box Generator</h2>
      </header>

      <BoxGeneratorForm poolId={poolId} onGenerated={setDraft} />

      {draft && (
        <section className="generator-section generator-results">
          <div className="generator-section-header">
            <h2>Results</h2>
            {/* This is not a field on the API response right now... */}
            {draft.using_reference_season && (
              <span className="reference-season-badge">reference season</span>
            )}
            {/* TODO: save action not yet wired up — this generator flow is preview-only for now */}
            <button className="btn-primary btn-sm" disabled>Save boxes</button>
          </div>
          <div className="result-box-list">
            {draft.boxes?.map((box) => <BoxPreview key={box.name} box={box} />)}
          </div>
        </section>
      )}
    </div>
  );
}
