import { useState, useCallback } from "react";
import { useAuth } from "../context/AuthContext";

const TEAMS = ["BOS", "MIN", "MTL", "NY", "OTT", "TOR", "SEA", "VAN"];
const POSITIONS = ["F", "D", "G"];
const ROOKIE_OPTIONS = [
  { label: "No", value: false },
  { label: "Yes", value: true },
  { label: "Any", value: null },
];

const DEFAULT_BOXES = [
  { name: "Forwards Box 1", position: "F", rookie: false, rank_range: { start: 0, end: 0 } },
  { name: "Forwards Box 2", position: "F", rookie: false, rank_range: { start: 1, end: 1 } },
  { name: "Forwards Box 3", position: "F", rookie: false, rank_range: { start: 2, end: 2 } },
  { name: "Forwards Box 4", position: "F", rookie: false, rank_range: { start: 3, end: 3 } },
  { name: "Forwards Box 5", position: "F", rookie: false, rank_range: { start: 4, end: 4 } },
  { name: "Defence Box 1", position: "D", rookie: false, rank_range: { start: 0, end: 0 } },
  { name: "Defence Box 2", position: "D", rookie: false, rank_range: { start: 1, end: 1 } },
  { name: "Defence Box 3", position: "D", rookie: false, rank_range: { start: 2, end: 2 } },
  { name: "Goalies Box 1", position: "G", rookie: null, rank_range: { start: 0, end: 0 } },
  { name: "Rookie Forwards Box 1", position: "F", rookie: true, rank_range: { start: 0, end: 0 } },
  { name: "Rookie Defence Box 1", position: "D", rookie: true, rank_range: { start: 0, end: 0 } },
];

function nextRankForPosition(boxes, position, rookie) {
  const matching = boxes.filter(b => b.position === position && b.rookie === rookie);
  if (matching.length === 0) return { start: 0, end: 0 };
  const maxEnd = Math.max(...matching.map(b => b.rank_range.end));
  return { start: maxEnd + 1, end: maxEnd + 1 };
}

function positionBadgeClass(position, rookie) {
  if (rookie === true) return "box-badge box-badge--rookie";
  if (position === "F") return "box-badge box-badge--forward";
  if (position === "D") return "box-badge box-badge--defense";
  return "box-badge box-badge--goalie";
}

function BoxConfigRow({ box, index, onChange, onRemove }) {
  return (
    <div className="box-config-row">
      <span className={positionBadgeClass(box.position, box.rookie)}>
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
        <input
          className="box-rank-input"
          type="number"
          min={1}
          value={box.rank_range.start + 1}
          onFocus={e => e.target.select()}
          onChange={e => {
            const val = Math.max(1, +e.target.value) - 1;
            onChange(index, "rank_range", { ...box.rank_range, start: val });
          }}
        />
        <span className="box-rank-label">–</span>
        <input
          className="box-rank-input"
          type="number"
          min={box.rank_range.start + 1}
          value={box.rank_range.end + 1}
          onFocus={e => e.target.select()}
          onChange={e => {
            const val = Math.max(box.rank_range.start + 1, +e.target.value) - 1;
            onChange(index, "rank_range", { ...box.rank_range, end: val });
          }}
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
        <span>Rank</span>
        <span></span>
      </div>
      <div className="box-config-list">
        {boxes.map((box, i) => (
          <BoxConfigRow key={i} box={box} index={i} onChange={onChange} onRemove={onRemove} />
        ))}
      </div>
    </div>
  );
}

const BoxGeneratorForm = ({ poolId, onGenerated }) => {
  const { authHeaders } = useAuth();

  const [teams, setTeams] = useState(new Set(TEAMS));
  const [maxPerTeam, setMaxPerTeam] = useState(1);
  const [boxes, setBoxes] = useState(DEFAULT_BOXES.map(b => ({ ...b, rank_range: { ...b.rank_range } })));
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
    const position = "F";
    const rookie = false;
    const rank_range = nextRankForPosition(boxes, position, rookie);
    setBoxes(prev => [...prev, {
      name: `Forwards Box ${prev.filter(b => b.position === "F" && !b.rookie).length + 1}`,
      position,
      rookie,
      rank_range,
    }]);
  };

  const generate = async () => {
    setError(null);
    setLoading(true);

    try {
      const res = await fetch(`/api/pools/${poolId}/pool_boxes/generate`, {
        method: "POST",
        headers: { ...authHeaders, "Content-Type": "application/json", "Accept": "application/json" },
        body: JSON.stringify({
          teams: [...teams],
          max_players_per_team: maxPerTeam || null,
          excluded_player_ids: [],
          boxes,
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
          <label className="generator-config-label">Max players per team</label>
          <input
            className="generator-config-input"
            type="number"
            min={1}
            value={maxPerTeam}
            onChange={e => setMaxPerTeam(e.target.value ? +e.target.value : "")}
          />
          <span className="helper-text">blank = global ranking</span>
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
