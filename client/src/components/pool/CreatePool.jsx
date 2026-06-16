import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useQuery, useMutation } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";
import LoadingState from "@c/shared/LoadingState";
import StepBadge from "@c/shared/StepBadge";

const FormField = ({ label, htmlFor, children }) => (
  <div className="form-field">
    <label className="form-label" htmlFor={htmlFor}>{label}</label>
    {children}
  </div>
);

export default function CreatePool() {
  const navigate = useNavigate();
  const { authHeaders } = useAuth();
  const [errorMsg, setErrorMsg] = useState(null);

  const [form, setForm] = useState({
    name: "",
    season_id: "",
    pool_type: "box_select",
    trade_policy: "disabled",
    reference_season_id: "",
  });
  const [useRefSeason, setUseRefSeason] = useState(false);

  const { data: meta, isLoading: metaLoading } = useQuery({
    queryKey: ["pools-meta"],
    queryFn: async () => {
      const res = await fetch("/api/pools/meta", { headers: authHeaders });
      if (!res.ok) throw new Error("Failed to load pool options");
      return res.json();
    },
    staleTime: 10 * 60 * 1000,
  });

  const createMutation = useMutation({
    mutationFn: async () => {
      const body = {
        pool: {
          name: form.name,
          season_id: form.season_id,
          pool_type: form.pool_type,
          trade_policy: form.trade_policy,
          league_id: meta.leagues[0]?.id,
          ...(useRefSeason && form.reference_season_id
            ? { reference_season_id: form.reference_season_id }
            : {}),
        },
      };

      const res = await fetch("/api/pools", {
        method: "POST",
        headers: authHeaders,
        body: JSON.stringify(body),
      });

      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.errors?.join(", ") || "Failed to create pool");
      }

      return res.json();
    },
    onSuccess: (data) => {
      navigate(`/pools/${data.id}/scoring/setup`);
    },
    onError: (err) => {
      setErrorMsg(err.message);
    },
  });

  const field = (key) => ({
    value: form[key],
    onChange: (e) => setForm((f) => ({ ...f, [key]: e.target.value })),
  });

  const canSubmit =
    form.name.trim() &&
    form.season_id &&
    !createMutation.isPending;

  if (metaLoading) {
    return (
      <div className="create-pool-page">
        <div className="create-pool-form">
          <LoadingState />
        </div>
      </div>
    );
  }

  return (
    <div className="create-pool-page">
      <div className="create-pool-form">
        <StepBadge label="New Pool" step={1} total={4} />
        <h2>Create Pool</h2>
        <p className="setup-page-subtitle">
          Set up the basics. You'll review boxes on the next step.
        </p>

        <div className="stack">
          <FormField label="Pool Name" htmlFor="pool-name">
            <input
              id="pool-name"
              className="form-input"
              placeholder="e.g. My PWHL Pool"
              autoFocus
              {...field("name")}
            />
          </FormField>

          <FormField label="Season" htmlFor="season">
            <select id="season" className="form-select" {...field("season_id")}>
              <option value="">Select a season…</option>
              {meta?.seasons?.map((s) => (
                <option key={s.id} value={s.id}>{s.name}</option>
              ))}
            </select>
          </FormField>

          {meta?.pool_types?.length > 1 && (
            <FormField label="Pool Type" htmlFor="pool-type">
              <select id="pool-type" className="form-select" {...field("pool_type")}>
                {meta.pool_types.map(({ value, label }) => (
                  <option key={value} value={value}>{label}</option>
                ))}
              </select>
            </FormField>
          )}

          <FormField label="Trade Policy" htmlFor="trade-policy">
            <select id="trade-policy" className="form-select" {...field("trade_policy")}>
              {meta?.trade_policies?.map(({ value, label }) => (
                <option key={value} value={value}>{label}</option>
              ))}
            </select>
          </FormField>

          <label className="form-toggle-row">
            <input
              type="checkbox"
              checked={useRefSeason}
              onChange={(e) => setUseRefSeason(e.target.checked)}
            />
            <span className="form-toggle-label">
              Use a reference season for player stats
            </span>
          </label>

          {useRefSeason && (
            <FormField label="Reference Season" htmlFor="ref-season">
              <select id="ref-season" className="form-select" {...field("reference_season_id")}>
                <option value="">Select a reference season…</option>
                {meta?.seasons
                  ?.filter((s) => s.id !== form.season_id)
                  .map((s) => (
                    <option key={s.id} value={s.id}>{s.name}</option>
                  ))}
              </select>
              <span className="helper-text">
                Player scores shown during selection will use this season's data.
              </span>
            </FormField>
          )}

          {errorMsg && (
            <div className="generator-error">{errorMsg}</div>
          )}

          <button
            className="btn-primary btn-full"
            onClick={() => createMutation.mutate()}
            disabled={!canSubmit}
          >
            {createMutation.isPending ? "Creating…" : "Continue to Scoring Setup →"}
          </button>
        </div>
      </div>
    </div>
  );
}
