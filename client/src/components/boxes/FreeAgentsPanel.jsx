import { useState, useMemo } from "react";
import { SortableContext, verticalListSortingStrategy } from "@dnd-kit/sortable";
import DraggablePlayer from "./DraggablePlayer";
import { matchesSearch } from "@/utils/searchUtils";
import { usePool } from "@/context/PoolContext";
import { getLeagueConstants } from "@/constants";
import { normalizePosition } from "@/utils/positionUtils";

export default function FreeAgentsPanel({ players, isDragTarget, search, onSearchChange }) {
  const { pool } = usePool();
  const { teams, teamCodes, positionGroups } = getLeagueConstants(pool?.league?.short_name);
  const [teamFilter, setTeamFilter] = useState(new Set(teamCodes));
  const [positionFilter, setPositionFilter] = useState(null);
  const [rookieFilter, setRookieFilter] = useState(null);
  const [sortDesc, setSortDesc] = useState(true);
  const POSITIONS = Object.keys(positionGroups);

  const toggleTeam = (team) => {
    setTeamFilter((prev) => {
      const next = new Set(prev);
      next.has(team) ? next.delete(team) : next.add(team);
      return next;
    });
  };

  const filtered = useMemo(() => {
    return players.
      filter((p) => {
        if (search && !matchesSearch(p.name, search)) return false;
        if (!teamFilter.has(p.current_team_short_code)) return false;
        if (positionFilter && normalizePosition(p.position, positionGroups) !== positionFilter) return false;
        if (rookieFilter !== null && p.rookie !== rookieFilter) return false;
        return true;
      }).
      sort((a, b) => sortDesc ? b.score - a.score : a.score - b.score);
  }, [players, search, teamFilter, positionFilter, rookieFilter, sortDesc, positionGroups]);

  return (
    <div className={`free-agents-panel ${isDragTarget ? "free-agents-panel--over" : ""}`}>
      <div className="free-agents-panel__header">
        <span className="free-agents-panel__title">
          Free Agents
          <span className="free-agents-panel__count">{players.length}</span>
        </span>
        <div className="player-drawer-mode-toggle">
          <button
            className={`player-drawer-mode-btn ${sortDesc ? "player-drawer-mode-btn--active" : ""}`}
            onClick={() => setSortDesc(true)}
          >
            Score ↓
          </button>
          <button
            className={`player-drawer-mode-btn ${!sortDesc ? "player-drawer-mode-btn--active" : ""}`}
            onClick={() => setSortDesc(false)}
          >
            Score ↑
          </button>
        </div>
      </div>

      <div className="free-agents-panel__filters">
        <input
          className="form-input"
          placeholder="Search players…"
          value={search}
          onChange={(e) => onSearchChange(e.target.value)}
        />

        <div className="team-toggle-list">
          {teamCodes.map((code) => (
            <button
              key={code}
              className={`team-toggle ${teamFilter.has(code) ? "team-toggle--active" : ""}`}
              style={teamFilter.has(code)
                ? { background: teams[code].bg, color: teams[code].text, borderColor: teams[code].bg }
                : {}
              }
              onClick={() => toggleTeam(code)}
            >
              {code}
            </button>
          ))}
        </div>
        <div className="free-agents-panel__team-controls">
          <button
            className="btn-link"
            onClick={() => setTeamFilter(new Set(Object.keys(teams).filter(c => c !== "default")))}
          >
            All
          </button>
          <span className="free-agents-panel__team-sep">·</span>
          <button
            className="btn-link"
            onClick={() => setTeamFilter(new Set())}
          >
            None
          </button>
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
