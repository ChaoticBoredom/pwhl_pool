import { useState } from "react";
import { fmt } from "@/utils/reportUtils";

export default function CollapsibleStandings({
  teams,
  hiddenIds,
  onToggle,
  colourMap,
  showActions = false,
  onSelectAll,
  onSelectNone,
  defaultOpen = false,
}) {
  const [open, setOpen] = useState(defaultOpen);
  const sorted = [...teams].sort((a, b) => b.total_score - a.total_score);

  return (
    <div className="rp-standings-bar">
      <button className="rp-standings-toggle" onClick={() => setOpen(o => !o)}>
        <span className="label-eyebrow label-eyebrow--sm">
          Standings ({teams.length} teams)
        </span>
        <span className="rp-standings-chevron">{open ? "▲" : "▼"}</span>
      </button>

      {open && (
        <>
          {showActions && (
            <div className="rp-standings-actions">
              <button className="btn-primary btn-sm" onClick={onSelectAll}>Select All</button>
              <button className="btn-primary btn-sm" onClick={onSelectNone}>Select None</button>
            </div>
          )}
          <div className="rp-standings-grid">
            {sorted.map((team, i) => (
              <div
                key={team.id}
                className={`standings-row${hiddenIds.has(team.id) ? " standings-row--hidden" : ""}`}
                onClick={() => onToggle(team.id)}
              >
                <span className="standings-rank">{i + 1}</span>
                <span className="standings-swatch" style={{ background: colourMap[team.id] }} />
                <span className="standings-name">{team.team_name}</span>
                <span className="stat-value stat-value--bold">{fmt(team.total_score)}</span>
              </div>
            ))}
          </div>
        </>
      )}
    </div>
  );
}
