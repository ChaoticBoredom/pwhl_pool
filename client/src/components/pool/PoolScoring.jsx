import { useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useQuery, useQueryClient, useMutation } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";
import useNotices from "@/hooks/useNotices";
import { ScoringSection } from "./ScoringSection";
import { usePool } from "@/context/PoolContext";
import { useLeagueConstants } from "@/constants/useLeagueConstants";
import LoadingState from "@c/shared/LoadingState";

export default function PoolScoring({ setupMode = false, editMode = false }) {
  const [editing, setEditing] = useState(setupMode || editMode);
  const { poolId } = useParams();
  const { authHeaders } = useAuth();
  const { add } = useNotices();
  const { isCommissioner } = usePool();
  const queryClient = useQueryClient();
  const navigate = useNavigate();
  const { rosterTypeLabels } = useLeagueConstants();

  const [values, setValues] = useState(null);

  const { data, isLoading, error } = useQuery({
    queryKey: ["pool-scoring", poolId],
    queryFn: async () => {
      const res = await fetch(`/api/pools/${poolId}/pool_scoring`, {
        headers: authHeaders,
      });
      if (!res.ok) throw new Error("Failed to load scoring");
      return res.json();
    },
    staleTime: 20 * 60 * 1000,
  });

  if (data && values === null) {
    setValues(
      Object.fromEntries(
        Object.entries(data).flatMap(([rosterType, fields]) =>
          fields.map((f) => [`${rosterType}/${f.field_name}`, f.value ?? ""])
        )
      )
    );
  }

  const handleChange = (fieldName, rosterType, value) => {
    setValues((prev) => ({ ...prev, [`${rosterType}/${fieldName}`]: value }));
  };

  const handleCancel = () => {
    setValues(null);
    setEditing(false);
    if (setupMode) {
      navigate(`/pools/${poolId}`);
    }
  }

  const saveMutation = useMutation({
    mutationFn: async () => {
      const scoring = Object.entries(data).flatMap(([rosterType, fields]) =>
        fields.map((f) => ({
          field_name: f.field_name,
          roster_type: rosterType,
          value: (() => {
            const v = values?.[`${rosterType}/${f.field_name}`];
            return v === "" ? null : Number(v);
          })(),
        }))
      );

      const res = await fetch(`/api/commissioner/${poolId}/pool_scoring`, {
        method: "PUT",
        headers: authHeaders,
        body: JSON.stringify({ scoring }),
      });

      if (!res.ok) throw new Error("Failed to save scoring");
    },
    onSuccess: () => {
      queryClient.removeQueries({ queryKey: ["pool-scoring", poolId] });
      queryClient.removeQueries({ queryKey: ["pool-boxes-generate", poolId] });
      setValues(null);
      if (setupMode) {
        navigate(`/pools/${poolId}/boxes/setup`);
      } else {
        setEditing(false);
        add({ severity: "success", message: "Scoring saved." });
      }
    },
    onError: (err) => {
      add({ severity: "error", message: err.message });
    },
  });

  if (isLoading || error) return <LoadingState error={error} />

  return (
    <div className="app-wrapper">
      {setupMode ? (
        <>
          <div className="setup-step-badge">New Pool — Step 2 of 3</div>
          <h1 className="setup-page-title">Configure Scoring</h1>
          <p className="setup-page-subtitle">
            Set point values for each stat. Leave blank or set to 0 to disable.
            Negative values are allowed.
          </p>
        </>
      ) : (
        <div className="selection-header">
          <h2 className="scoring-page-title">Scoring Rules</h2>
          {isCommissioner && !editing && (
            <button className="btn-primary btn-top" onClick={() => setEditing(true)}>
              Edit Scoring
            </button>
          )}
        </div>
      )}

      {data && values && Object.entries(data).map(([rosterType, fields]) => (
        <ScoringSection
          key={rosterType}
          title={rosterTypeLabels[rosterType] ?? rosterType}
          scorings={fields.
            filter((f) => editing || f.value !== null).
            map((f) => ({
              ...f,
              roster_type: rosterType,
              value: editing ? (values[`${rosterType}/${f.field_name}`] ?? "") : f.value,
          }))}
          editable={editing}
          onChange={handleChange}
        />
      ))}

      {editing && (
        <div className="setup-confirm-bar">
          <button
            className="btn-secondary btn-sm"
            onClick={handleCancel}
          >
            Cancel
          </button>
          <button
            className="btn-primary"
            onClick={() => saveMutation.mutate()}
            disabled={saveMutation.isPending}
          >
            {saveMutation.isPending ? "Saving…" : setupMode ? "Save & Continue →" : "Save Scoring"}
          </button>
        </div>
      )}
    </div>
  );
}
