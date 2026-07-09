import { useState, useMemo } from "react";
import { SortableContext, verticalListSortingStrategy } from "@dnd-kit/sortable";
import DraggablePlayer from "./DraggablePlayer";
import { matchesSearch } from "@/utils/searchUtils";
import { useLeagueConstants } from "@/constants/useLeagueConstants";
import { normalizePosition } from "@/utils/positionUtils";
import { TeamToggleList } from "@c/shared/TeamToggleList";
import { ToggleGroup } from "@c/shared/ToggleGroup";

export default function FreeAgentsPanel({ players, isDragTarget, search, onSearchChange }) {
  const { teams, teamCodes, positionGroups } = useLeagueConstants();
  const POSITIONS = Object.keys(positionGroups);
  const [teamFilter, setTeamFilter] = useState(new Set(teamCodes));
  const [positionFilters, setPositionFilters] = useState(new Set(POSITIONS));
  const [rookieFilter, setRookieFilter] = useState(null);
  const [sortDesc, setSortDesc] = useState(true);

  const filtered = useMemo(() => {
    return players.
      filter((p) => {
        if (search && !matchesSearch(p.name, search)) return false;
        if (!teamFilter.has(p.current_team_short_code)) return false;
        if (!positionFilters.has(normalizePosition(p.position, positionGroups))) return false;
        if (rookieFilter !== null && p.rookie !== rookieFilter) return false;
        return true;
      }).
      sort((a, b) => sortDesc ? b.score - a.score : a.score - b.score);
  }, [players, search, teamFilter, positionFilters, rookieFilter, sortDesc, positionGroups]);

  return (
    <div className={`free-agents-panel panel ${isDragTarget ? "free-agents-panel--over" : ""}`}>
      <div className="panel__header panel__header--split">
        <span className="free-agents-panel__title">
          Free Agents
          <span className="free-agents-panel__count">{players.length}</span>
        </span>
        <ToggleGroup
          mode="exclusive"
          className="toggle-btn"
          options={[{ label: "Score ↓", value: true }, { label: "Score ↑", value: false }]}
          value={sortDesc}
          onChange={setSortDesc}
        />
      </div>

      <div className="free-agents-panel__filters">
        <input
          className="form-input"
          placeholder="Search players..."
          value={search}
          onChange={(e) => onSearchChange(e.target.value)}
        />

        <TeamToggleList
          teamCodes={teamCodes}
          teams={teams}
          selected={teamFilter}
          onChange={setTeamFilter}
        />

        <div className="free-agents-panel__filter-row">
          <ToggleGroup
            mode="multi"
            className="filter-toggle"
            options={POSITIONS.map((pos) => ({ label: pos, value: pos }))}
            value={positionFilters}
            onChange={setPositionFilters}
          />

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
