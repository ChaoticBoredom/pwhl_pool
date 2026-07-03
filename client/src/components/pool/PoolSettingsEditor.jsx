import { useState } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";

function SettingsField({ label, children }) {
  return (
    <div className="scoring-card">
      <span className="scoring-section-title label-eyebrow label-eyebrow--md">{label}</span>
      {children}
    </div>
  );
}

function NameField({ value, onChange, editable }) {
  if (!editable) return <p>{value}</p>;

  return (
    <input
      id="pool-name"
      className="form-input"
      type="text"
      value={value}
      onChange={(e) => onChange(e.target.value)}
    />
  );
}

function SeasonField({ value, seasons, creation, onChange }) {
  if (!creation) return <p>{seasons?.find((s) => s.id === value)?.name ?? value}</p>;

  return (
    <select className="form-select" value={value} onChange={(e) => onChange(e.target.value)}>
      <option value="">Select a season...</option>
      {seasons?.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
    </select>
  );
}

function PoolTypeField({ value, poolTypes, creation, onChange }) {
  if (!creation) return <p>{poolTypes?.find((t) => t.value === value)?.label ?? value}</p>;

  return (
    <select className="form-select" value={value} onChange={(e) => onChange(e.target.value)}>
      {poolTypes?.map(({ value: v, label }) => <option key={v} value={v}>{label}</option>)}
    </select>
  );
}

function TradePolicyField({ value, tradePolicies, editable, onChange }) {
  if (!editable) return <p>{tradePolicies?.find((t) => t.value === value)?.label ?? value}</p>;

  return (
    <div className="stack">
      {tradePolicies?.map(({ value: v, label }) => (
        <label key={v} className="radio-option">
          <input
            type="radio"
            name="trade_policy"
            value={v}
            checked={value === v}
            onChange={() => onChange(v)}
          />
          <span>{label}</span>
        </label>
      ))}
    </div>
  );
}

function ReferenceSeasonField({ value, seasons, currentSeasonId, editable, useRefSeason, onToggle, onChange }) {
  if (!editable) return <p>{value ? (seasons?.find((s) => s.id === value)?.name ?? value) : "None (current season)"}</p>;

  return (
    <>
      <p className="setup-page-subtitle">
        Use stats from a previous season to rank players for box generation.
        Leave blank to use the current season.
      </p>
      <label className="form-toggle-row">
        <input
          type="checkbox"
          checked={useRefSeason}
          disabled={!editable}
          onChange={(e) => {
            onToggle(e.target.checked);
            if (!e.target.checked) onChange("");
          }}
        />
        <span className="form-toggle-label">Use a reference season</span>
      </label>
      {useRefSeason && (
        <select
          className="form-select"
          value={value}
          disabled={!editable}
          onChange={(e) => onChange(e.target.value)}
        >
          <option value="">Select a reference season...</option>
          {seasons?.filter((s) => s.id !== currentSeasonId).map((s) => (
            <option key={s.id} value={s.id}>{s.name}</option>
          ))}
        </select>
      )}
    </>
  );
}

export default function PoolSettingsEditor({ poolId, data, mode, onSave, onCancel, saveLabel }) {
  const creation = mode === "creating";
  const editable = mode !== "viewing";

  if (creation && poolId) {
    console.error("PoolSettingsEditor: mode is 'creating' but poolId was provided");
  }

  if (!creation && !data) {
    console.error("PoolSettingsEditor: mode is not 'creating' but no data was provided");
  }

  const { authHeaders } = useAuth();

  const [values, setValues] = useState({
    name: data?.name ?? "",
    season_id: data?.season_id ?? "",
    pool_type: data?.pool_type ?? "box_select",
    trade_policy: data?.trade_policy ?? "disabled",
    reference_season_id: data?.reference_season_id ?? "",
  });
  const [useRefSeason, setUseRefSeason] = useState(!!data?.reference_season_id);

  const field = (key) => (value) => setValues((v) => ({ ...v, [key]: value }));

  const { data: meta } = useQuery({
    queryKey: ["pools-meta"],
    queryFn: async () => {
      const res = await fetch("/api/pools/meta", { headers: authHeaders });
      if (!res.ok) throw new Error("Failed to load pool options");
      return res.json();
    },
    staleTime: Infinity,
  });

  const saveMutation = useMutation({
    mutationFn: async () => {
      const body = {
        pool: {
          name: values.name,
          trade_policy: values.trade_policy,
          reference_season_id: values.reference_season_id || null,
          ...(creation
            ? {
                season_id: values.season_id,
                pool_type: values.pool_type,
                // TODO: hardcoded to the only league that currently exists.
                // Revisit once multi-league support is added (likely as its own
                // earlier step, not embedded in this form).
                league_id: meta?.leagues?.[0]?.id,
              }
            : {}),
        },
      };

      const res = await fetch(
        creation ? "/api/pools" : `/api/commissioner/${poolId}`,
        {
          method: creation ? "POST" : "PUT",
          headers: authHeaders,
          body: JSON.stringify(body),
        }
      );

      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.errors?.join(", ") || "Failed to save pool settings");
      }

      return res.json();
    },
  });

  const handleSaveClick = () => onSave(() => saveMutation.mutateAsync());
  const canSave = values.name.trim() && (!creation || values.season_id) && (!useRefSeason || values.reference_season_id);

  return (
    <div className="stack">
      <SettingsField label="Pool Name">
        <NameField value={values.name} onChange={field("name")} editable={editable} />
      </SettingsField>

      <SettingsField label="Season">
        <SeasonField value={values.season_id} seasons={meta?.seasons} creation={creation} onChange={field("season_id")} />
      </SettingsField>

      <SettingsField label="Pool Type">
        <PoolTypeField value={values.pool_type} poolTypes={meta?.pool_types} creation={creation} onChange={field("pool_type")} />
      </SettingsField>

      <SettingsField label="Trade Policy">
        <TradePolicyField
          value={values.trade_policy}
          tradePolicies={meta?.trade_policies}
          editable={editable}
          onChange={field("trade_policy")}
        />
      </SettingsField>

      <SettingsField label="Reference Season">
        <ReferenceSeasonField
          value={values.reference_season_id}
          seasons={meta?.seasons}
          currentSeasonId={values.season_id}
          editable={editable}
          onChange={field("reference_season_id")}
          useRefSeason={useRefSeason}
          onToggle={setUseRefSeason}
        />
      </SettingsField>

      {saveMutation.isError && <div className="generator-error">{saveMutation.error.message}</div>}

      {editable && (
        <div className="setup-confirm-bar">
          <button className="btn-secondary btn-sm" onClick={onCancel}>Cancel</button>
          <button className="btn-primary" onClick={handleSaveClick} disabled={saveMutation.isPending || !canSave}>
            {saveMutation.isPending ? "Saving..." : saveLabel ?? "Save Settings"}
          </button>
        </div>
      )}
    </div>
  );
}
