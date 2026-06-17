import { useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";
import { usePool } from "@/context/PoolContext";
import useNotices from "@/hooks/useNotices";
import LoadingState from "@c/shared/LoadingState";

const SettingsCard = ({ title, children }) => (
  <div className="scoring-card">
    <span className="scoring-section-title">{title}</span>
    {children}
  </div>
);

const RadioOption = ({ name, value, checked, onChange, label }) => (
  <label className="radio-option">
    <input
      type="radio"
      name={name}
      value={value}
      checked={checked}
      onChange={onChange}
    />
    <span>{label}</span>
  </label>
);

export default function PoolSettings() {
  const { poolId } = useParams();
  const navigate = useNavigate();
  const { authHeaders } = useAuth();
  const { pool } = usePool();
  const { add } = useNotices();
  const queryClient = useQueryClient();

  const [values, setValues] = useState({
    name: pool?.name ?? "",
    trade_policy: pool?.trade_policy ?? "",
    reference_season_id: pool?.reference_season_id ?? "",
  });

  const { data: meta, isLoading } = useQuery({
    queryKey: ["pools-meta"],
    queryFn: async () => {
      const res = await fetch("/api/pools/meta", { headers: authHeaders });
      if (!res.ok) throw new Error("Failed to load meta");
      return res.json();
    },
    staleTime: Infinity,
  });

  const saveMutation = useMutation({
    mutationFn: async () => {
      const res = await fetch(`/api/commissioner/${poolId}`, {
        method: "PUT",
        headers: authHeaders,
        body: JSON.stringify({
          pool: {
            name: values.name,
            trade_policy: values.trade_policy,
            reference_season_id: values.reference_season_id || null,
          },
        }),
      });
      if (!res.ok) throw new Error("Failed to save settings");
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["pool", poolId] });
      add({ severity: "success", message: "Pool settings saved." });
      navigate(-1);
    },
    onError: (err) => {
      add({ severity: "error", message: err.message });
    },
  });

  if (isLoading) return <LoadingState message="Loading settings..." />;

  return (
    <div className="app-wrapper">
      <h1 className="setup-page-title">Pool Settings</h1>

      <div className="stack">
        <div className="scoring-card">
          <label className="scoring-section-title" htmlFor="pool-name">Pool Name</label>
          <input
            id="pool-name"
            type="text"
            value={values.name}
            onChange={(e) => setValues((v) => ({ ...v, name: e.target.value }))}
          />
        </div>

        <SettingsCard title="Trade Policy">
          <div className="stack">
            {meta?.trade_policies?.map(({ value, label }) => (
              <RadioOption
                key={value}
                value={value}
                checked={values.trade_policy === value}
                onChange={() => setValues((v) => ({ ...v, trade_policy: value}))}
                label={label}
              />
            ))}
          </div>
        </SettingsCard>

        <SettingsCard title="Reference Season">
          <p className="setup-page-subtitle">
            Use stats from a previous season to rank players for box generation.
            Leave blank to use the current season.
          </p>
          <div className="stack">
            <RadioOption
              name="reference_season_id"
              value=""
              checked={!values.reference_season_id}
              onChange={() => setValues((v) => ({ ...v, reference_season_id: "" }))}
              label="None (use current season)"
            />
            {meta?.season?.
              filter((s) => s.id !== pool.season_id)?.
              map((season) => (
                <RadioOption
                  key={season.id}
                  name="reference_season_id"
                  value={season.id}
                  checked={values.reference_season_id === season.id}
                  onChange={() => setValues((v) => ({ ...v, reference_season_id: season.id }))}
                  label={season.name}
                />
              ))
            }
          </div>
        </SettingsCard>
      </div>

      <div className="setup-confirm-bar">
        <button
          className="btn-secondary btn-sm"
          onClick={() => navigate(-1)}
        >
          Cancel
        </button>
        <button
          className="btn-primary"
          onClick={() => saveMutation.mutate()}
          disabled={saveMutation.isPending || !values.name.trim()}
        >
          {saveMutation.isPending ? "Saving..." : "Save Settings"}
        </button>
      </div>
    </div>
  );
}
