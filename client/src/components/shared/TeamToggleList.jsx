import { ToggleGroup } from "@c/shared/ToggleGroup";

export function TeamToggleList({ teamCodes, teams, selected, onChange }) {
  const options = teamCodes.map((code) => ({
    label: code,
    value: code,
    style: selected.has(code)
      ? { background: teams[code].bg, color: teams[code].text, borderColor: teams[code].bg }
      : undefined,
  }));

  const selectAll = () => onChange(new Set(Object.keys(teams).filter((c) => c !== "default")));
  const selectNone = () => onChange(new Set());

  return (
    <div>
      <ToggleGroup
        mode="multi"
        className="team-toggle"
        options={options}
        value={selected}
        onChange={onChange}
      />
      <div className="free-agents-panel__team-controls">
        <button className="btn-link" onClick={selectAll}>All</button>
        <span className="free-agents-panel__team-sep">·</span>
        <button className="btn-link" onClick={selectNone}>None</button>
      </div>
    </div>
  );
}
