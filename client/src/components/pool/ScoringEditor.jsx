import { ScoringSection } from "..ScoringSection";
import { useLeagueConstants } from "@/constants/useLeagueConstants";

export default function ScoringEditor({
  data,
  values,
  editable,
  isSaving,
  onActions,
  saveLabel = "Save Scoring",
}) {
  const { rosterTypeLabels } = useLeagueConstants();

  return (
    <>
      {Object.entries(data).map(([rosterType, fields]) => (
        <ScoringSection
          key={rosterType}
          title={rosterTypeLabels[rosterType] ?? rosterType}
          scorings={fields
            .filter((f) => editable || f.value !== null)
            .map((f) => ({
              ...f,
              roster_type: rosterType,
              value: editable ? (values[`${rosterType}/${f.field_name}`] ?? "") : f.value,
            }))}
          editable={editable}
          onChange={onActions.change}
        />
      ))}

      {editable && onActions && (
        <div className="setup-confirm-bar">
          <button className="btn-secondary btn-sm" onClick={onActions.cancel}>
            Cancel
          </button>
          <button
            className="btn-primary"
            onClick={onActions.save}
            disabled={isSaving}
          >
            {isSaving ? "Saving..." : saveLabel}
          </button>
        </div>
      )}
    </>
  );
}
