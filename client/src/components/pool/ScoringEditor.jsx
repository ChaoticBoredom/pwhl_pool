import { useMutation } from "@tanstack/react-query";
import { useState } from "react";
import { useAuth } from "@/context/AuthContext";
import { ScoringSection } from "./ScoringSection";
import { useLeagueConstants } from "@/constants/useLeagueConstants";

export default function ScoringEditor({ poolId, data, editable, onSave, onCancel, saveLabel }) {
  const { authHeaders } = useAuth();
  const { statTypeLabels } = useLeagueConstants();

  const [values, setValues] = useState(() =>
    Object.fromEntries(
      Object.values(data).flatMap((fields) =>
        fields.map((f) => [`${f.stat_type}/${f.field_name}`, f.value])
      )
    )
  );

  const handleChange = (fieldName, statType, value) => {
    setValues((prev) => ({ ...prev, [`${statType}/${fieldName}`]: value }));
  };

  const saveMutation = useMutation({
    mutationFn: async () => {
      const allFields = Object.values(data).flat();
      const needsCreate = allFields.every((f) => f.id === null);

      const res = await fetch(`/api/commissioner/${poolId}/pool_scoring`, {
        method: needsCreate ? "POST" : "PUT",
        headers: authHeaders,
        body: JSON.stringify({
          scoring: allFields.map((f) => ({
            id: f.id,
            field_name: f.field_name,
            stat_type: f.stat_type,
            value: Number(values[`${f.stat_type}/${f.field_name}`]),
          })),
        }),
      });

      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.error || "Failed to save scoring");
      }
    },
  });

  const handleSaveClick = () => onSave(() => saveMutation.mutateAsync());
  const canSave = Object.values(values).some((v) => Number(v) !== 0);

  return (
    <>
      {saveMutation.isError && <div className="generator-error">{saveMutation.error.message}</div>}

      {Object.entries(data).map(([statType, fields]) => (
        <ScoringSection
          key={statType}
          title={statTypeLabels[statType] ?? statType}
          scorings={fields.map((f) => ({
            ...f,
            value: editable ? values[`${statType}/${f.field_name}`] : f.value,
          }))}
          editable={editable}
          onChange={handleChange}
        />
      ))}

      {editable && (
        <div className="setup-confirm-bar">
          <button className="btn-secondary btn-sm" onClick={onCancel}>Cancel</button>
          <button
            className="btn-primary"
            onClick={handleSaveClick}
            disabled={saveMutation.isPending || !canSave}
            title={!canSave ? "Must have at least one non-zero scoring" : undefined}
          >
            {saveMutation.isPending ? "Saving..." : saveLabel ?? "Save Scoring"}
          </button>
        </div>
      )}
    </>
  );
}
