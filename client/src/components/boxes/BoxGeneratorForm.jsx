import { useState, useCallback } from "react";
import { useAuth } from "@/context/AuthContext";
import { DEFAULT_BOXES, boxBadgeClass } from "@/utils/boxConfig";

const TEAMS = ["BOS", "MIN", "MTL", "NY", "OTT", "TOR", "SEA", "VAN"];
const POSITIONS = ["F", "D", "G"];
const ROOKIE_OPTIONS = [
  { label: "No", value: false },
  { label: "Yes", value: true },
  { label: "Any", value: null },
];
const SEASONS = [
  { label: "Pool default", value: null },
  { label: "Regular Season", value: "8" },
  { label: "Playoffs", value: "9" },
];

function deriveRank(boxes, currentIndex) {
  const current = boxes[currentIndex];
  return boxes
    .slice(0, currentIndex)
    .filter(b => b.position === current.position && b.rookie === current.rookie)
    .reduce((sum, b) => sum + b.count, 1);
}

function buildPayloadBoxes(boxes) {
  return boxes.map((box, i) => ({
    name: box.name,
    position: box.position,
    rookie: box.rookie,
    rank: deriveRank(boxes, i),
    count: box.count,
  }));
}

function BoxConfigRow({ box, index, onChange, onRemove, derivedRank }) {
  return (
    <div className="box-config-row">
      <span className={boxBadgeClass(box.position, box.rookie)}>
        {box.rookie === true ? `R${box.position}` : box.position}
      </span>

      <input
        className="box-name-input"
        value={box.name}
        onChange={e => onChange(index, "name", e.target.value)}
      />

      <select
        className="box-select"
        value={box.position}
        onChange={e => onChange(index, "position", e.target.value)}
      >
        {POSITIONS.map(p => <option key={p} value={p}>{p}</option>)}
      </select>

      <select
        className="box-select"
        value={String(box.rookie)}
        onChange={e => {
          const val = e.target.value === "true" ? true : e.target.value === "false" ? false : null;
          onChange(index, "rookie", val);
        }}
      >
        {ROOKIE_OPTIONS.map(o => (
          <option key={String(o.value)} value={String(o.value)}>{o.label}</option>
        ))}
      </select>

      <div className="box-rank-range">
        <span className="box-rank-label">rank {derivedRank}</span>
        <span className="box-rank-label">+</span>
        <input
          className="box-rank-input"
          type="number"
          min={1}
          value={box.count}
          onFocus={e => e.target.select()}
          onChange={e => onChange(index, "count", Math.max(1, +e.target.value))}
        />
      </div>

      <button className="box-remove-btn" onClick={() => onRemove(index)} aria-label="Remove box">×</button>
    </div>
  );
}

function BoxConfigTable({ boxes, onChange, onRemove }) {
  return (
    <div className="box-config-table-wrapper">
      <div className="box-config-table-header">
        <span></span>
        <span>Name</span>
        <span>Position</span>
        <span>Rookie</span>
        <span>Rank × Count</span>
        <span></span>
      </div>
      <div className="box-config-list">
        {boxes.map((box, i) => (
          <BoxConfigRow
            key={i}
            box={box}
            index={i}
            onChange={onChange}
            onRemove={onRemove}
            derivedRank={deriveRank(boxes, i)}
          />
        ))}
      </div>
    </div>
  );
}

const BoxGeneratorForm = ({ poolId, onGenerated }) => {
  const { authHeaders } = useAuth();

  const [teams, setTeams] = useState(new Set(TEAMS));
  const [scope, setScope] = useState("per_team");
  const [seasonId, setSeasonId] = useState(null);
  const [boxes, setBoxes] = useState(DEFAULT_BOXES.map(b => ({ ...b })));
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const toggleTeam = code => {
    setTeams(prev => {
      const next = new Set(prev);
      next.has(code) ? next.delete(code) : next.add(code);
      return next;
    });
  };

  const updateBox = useCallback((index, field, value) => {
    setBoxes(prev => prev.map((b, i) => i === index ? { ...b, [field]: value } : b));
  }, []);

  const removeBox = useCallback(index => {
    setBoxes(prev => prev.filter((_, i) => i !== index));
  }, []);

  const addBox = () => {
    setBoxes(prev => [...prev, {
      name: `Forwards Box ${prev.filter(b => b.position === "F" && !b.rookie).length + 1}`,
      position: "F",
      rookie: false,
      count: 1,
    }]);
  };

  const generate = async () => {
    setError(null);
    setLoading(true);

    try {
      const res = await fetch(`/api/commissioner/${poolId}/pool_boxes/generate`, {
        method: "POST",
        headers: authHeaders,
        body: JSON.stringify({
          teams: [...teams],
          scope,
          season_id: seasonId,
          excluded_player_ids: [],
          boxes: buildPayloadBoxes(boxes),
        }),
      });

      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        throw new Error(body.error || `Request failed: ${res.status}`);
      }

      const data = await res.json();
      onGenerated(data);
    } catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <section className="generator-section">
        <h2>Teams</h2>
        <div className="team-toggle-list">
          {TEAMS.map(code => (
            <button
              key={code}
              onClick={() => toggleTeam(code)}
              className={`team-toggle ${teams.has(code) ? "team-toggle--active" : ""}`}
            >
              {code}
            </button>
          ))}
        </div>
      </section>

      <section className="generator-section">
        <h2>Config</h2>
        <div className="generator-config-row">
          <label className="generator-config-label">Scope</label>
          <div className="player-drawer-mode-toggle">
            {[
              { label: "Per team", value: "per_team" },
              { label: "Global", value: "global" },
            ].map(({ label, value }) => (
              <button
                key={value}
                className={`player-drawer-mode-btn ${scope === value ? "player-drawer-mode-btn--active" : ""}`}
                onClick={() => setScope(value)}
              >
                {label}
              </button>
            ))}
          </div>
        </div>

        <div className="generator-config-row">
          <label className="generator-config-label">Season</label>
          <div className="player-drawer-mode-toggle">
            {SEASONS.map(({ label, value }) => (
              <button
                key={String(value)}
                className={`player-drawer-mode-btn ${seasonId === value ? "player-drawer-mode-btn--active" : ""}`}
                onClick={() => setSeasonId(value)}
              >
                {label}
              </button>
            ))}
          </div>
        </div>
      </section>

      <section className="generator-section">
        <div className="generator-section-header">
          <h2>Boxes</h2>
          <button className="btn-primary btn-sm" onClick={addBox}>+ Add box</button>
        </div>
        <BoxConfigTable boxes={boxes} onChange={updateBox} onRemove={removeBox} />
      </section>

      <button
        className="btn-primary btn-full"
        onClick={generate}
        disabled={loading || teams.size === 0}
      >
        {loading ? "Generating…" : "Generate boxes"}
      </button>

      {error && <div className="generator-error">{error}</div>}
    </>
  );
};

export default BoxGeneratorForm;
