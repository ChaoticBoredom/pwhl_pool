import { useState, useMemo } from "react";
import { SortableContext, verticalListSortingStrategy } from "@dnd-kit/sortable";
import DraggablePlayer from "./DraggablePlayer";
import { POSITION_GROUPS, normalizePosition } from "@/utils/positionUtils";
import { normalizeString } from "@/utils/searchUtils";
import { PWHL_TEAMS } from "@/constants/teams";

const POSITIONS = Object.keys(POSITION_GROUPS);

export default function FreeAgentsPanel({ players, isDragTarget }) {
  const [search, setSearch] = useState("");
  const [teamFilter, setTeamFilter] = useState(new Set());
  const [positionFilter, setPositionFilter] = useState(null);
  const [rookieFilter, setRookieFilter] = useState(null);
  const [sortDesc, setSortDesc] = useState(true);

  const toggleTeam = (team) => {
    setTeamFilter((prev) => {
      const next = new Set(prev);
      next.has(team) ? next.delete(team) : next.add(team);
      return next;
    });
  };

  const filtered = useMemo(() => {
    return players
      .filter((p) => {
        if (search && !normalizeString(p.name).toLowerCase().includes(normalizeString(search).toLowerCase())) return false;
        if (teamFilter.size > 0 && !teamFilter.has(p.current_team_short_code)) return false;
        if (positionFilter && normalizePosition(p.position) !== positionFilter) return false;
        if (rookieFilter !== null && p.rookie !== rookieFilter) return false;
        return true;
      })
      .sort((a, b) => sortDesc ? b.score - a.score : a.score - b.score);
  }, [players, search, teamFilter, positionFilter, rookieFilter, sortDesc]);

  return (
    <div className={`free-agents-panel ${isDragTarget ? "free-agents-panel--over" : ""}`}>
      <div className="free-agents-panel__header">
        <span className="free-agents-panel__title">
          Free Agents
          <span className="free-agents-panel__count">{players.length}</span>
        </span>
        <button
          className={`player-drawer-mode-btn ${sortDesc ? "player-drawer-mode-btn--active" : ""}`}
          onClick={() => setSortDesc((d) => !d)}
        >
          {sortDesc ? "Score ↓" : "Score ↑"}
        </button>
      </div>

      <div className="free-agents-panel__filters">
        <input
          className="form-input"
          placeholder="Search players…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />

        <div className="team-toggle-list">
          {Object.entries(PWHL_TEAMS)
            .filter(([code]) => code !== "default")
            .map(([code, team]) => (
              <button
                key={code}
                className={`team-toggle ${teamFilter.has(code) ? "team-toggle--active" : ""}`}
                style={teamFilter.has(code)
                  ? { background: team.bg, color: team.text, borderColor: team.bg }
                  : {}
                }
                onClick={() => toggleTeam(code)}
              >
                {code}
              </button>
            ))}
        </div>

        <div className="free-agents-panel__filter-row">
          <div className="free-agents-panel__filter-group">
            {POSITIONS.map((pos) => (
              <button
                key={pos}
                className={`filter-toggle ${positionFilter === pos ? "filter-toggle--active" : ""}`}
                onClick={() => setPositionFilter((p) => p === pos ? null : pos)}
              >
                {pos}
              </button>
            ))}
          </div>

          <button
            className={`filter-toggle filter-toggle--rookie ${rookieFilter ? "filter-toggle--active" : ""}`}
            onClick={() => setRookieFilter((r) => !r || null)}
          >
            ★ Rookie
          </button>
        </div>
      </div>

      <SortableContext
        items={filtered.map((p) => p.id)}
        strategy={verticalListSortingStrategy}
      >
        <div className="free-agents-panel__players">
          {filtered.map((player) => (
            <DraggablePlayer key={player.id} player={player} />
          ))}
          {filtered.length === 0 && (
            <p className="free-agents-panel__empty">No players match your filters.</p>
          )}
        </div>
      </SortableContext>
    </div>
  );
}
