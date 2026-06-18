import { useMutation } from "@tanstack/react-query";
import { useState } from "react";
import { useAuth } from "@/context/AuthContext";
import { ScoringSection } from "./ScoringSection";
import { useLeagueConstants } from "@/constants/useLeagueConstants";

export default function ScoringEditor({ poolId, data, editable, onSave, onCancel, saveLabel }) {
  const { authHeaders } = useAuth();
  const { rosterTypeLabels } = useLeagueConstants();

  const [values, setValues] = useState(() =>
    Object.fromEntries(
      Object.values(data).flatMap((fields) =>
        fields.map((f) => [`${f.roster_type}/${f.field_name}`, f.value])
      )
    )
  );

  const handleChange = (fieldName, rosterType, value) => {
    setValues((prev) => ({ ...prev, [`${rosterType}/${fieldName}`]: value }));
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
            roster_type: f.roster_type,
            value: Number(values[`${f.roster_type}/${f.field_name}`]),
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

  return (
    <>
      {saveMutation.isError && <div className="generator-error">{saveMutation.error.message}</div>}

      {Object.entries(data).map(([rosterType, fields]) => (
        <ScoringSection
          key={rosterType}
          title={rosterTypeLabels[rosterType] ?? rosterType}
          scorings={fields.map((f) => ({
            ...f,
            value: editable ? values[`${rosterType}/${f.field_name}`] : f.value,
          }))}
          editable={editable}
          onChange={handleChange}
        />
      ))}

      {editable && (
        <div className="setup-confirm-bar">
          <button className="btn-secondary btn-sm" onClick={onCancel}>Cancel</button>
          <button className="btn-primary" onClick={handleSaveClick} disabled={saveMutation.isPending}>
            {saveMutation.isPending ? "Saving..." : saveLabel ?? "Save Scoring"}
          </button>
        </div>
      )}
    </>
  );
}
