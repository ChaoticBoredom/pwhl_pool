import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";
import { formatDate } from "@/utils/formatDate";
import IconButton from "@c/shared/IconButton";
import { ToggleGroup } from "@c/shared/ToggleGroup";
import { X } from "lucide-react";

const TABS = [
  { value: "today", label: "Today" },
  { value: "week_to_date", label: "Week" },
  { value: "month_to_date", label: "Month" },
  { value: "season_to_date", label: "Season" },
];

function formatToi(seconds) {
  if (!seconds) return "0:00";
  return `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, "0")}`;
}

function StatRow({ field, rawValue, pointValue, mode, label }) {
  const isDisplayOnly = pointValue === 0 && rawValue !== 0;
  const showPoints = mode === "points" && !isDisplayOnly;

  let display;
  if (field === "time_on_ice") {
    display = formatToi(rawValue);
  } else if (field === "plus_minus") {
    display = rawValue > 0 ? `+${rawValue}` : String(rawValue ?? 0);
  } else if (field === "penalty_minutes") {
    display = showPoints ? (pointValue === 0 ? "-" : `+${Number(pointValue).toFixed(2)}`) : `${rawValue ?? 0}m`;
  } else if (showPoints) {
    const pts = pointValue ?? 0;
    display = pts === 0 ? "—" : `${pts > 0 ? "+" : ""}${Number(pts).toFixed(2)}`;
  } else {
    display = rawValue ?? 0;
  }

  return (
    <div className="player-drawer-stat-row">
      <span className="player-drawer-stat-label">{label}</span>
      <span className={`stat-value ${isDisplayOnly ? "stat-value--dim" : "stat-value--bold"}`}>
        {display}
      </span>
    </div>
  );
}

// poolId: if provided, fetches from league_players#show (no clip toggle)
// otherwise fetches from team_player (full drawer with clip toggle)
export function PlayerStatsDrawer({ player, isOpen, onClose, drawerState, onDrawerChange, poolId }) {
  const { authHeaders } = useAuth();
  const { tab, mode, clipped } = drawerState;
  const isLeagueMode = !!poolId;

  const queryUrl = isLeagueMode
    ? `/api/players/${player.id}?pool_id=${poolId}`
    : `/api/players/${player.id}/team_player`;

  const { data, isLoading, isError } = useQuery({
    queryKey: isLeagueMode
      ? ["player-league-detail", player.id, poolId]
      : ["player-detail", player.id],
    queryFn: () =>
      fetch(queryUrl, { headers: authHeaders }).then(r => r.json()),
    enabled: isOpen,
    staleTime: 5 * 60 * 1000,
  });

  if (!isOpen) return null;

  const labels = data?.labels ?? {};
  const effectiveClipped = isLeagueMode ? false : clipped;

  const rawSource = effectiveClipped ? data?.raw_stats?.clipped_scores : data?.raw_stats?.scores;
  const periodRaw = rawSource?.[tab] ?? {};

  const pointSource = effectiveClipped ? data?.expanded_pool_scores?.clipped_scores : data?.expanded_pool_scores?.scores;
  const periodPoints = pointSource?.[tab] ?? {};

  const totalSource = effectiveClipped ? data?.pool_scores?.clipped_scores : data?.pool_scores?.scores;
  const periodTotal = totalSource?.[tab] ?? 0;

  const relevantFields = Object.keys(data?.raw_stats?.scores?.season_to_date ?? {});

  return (
    <div className="player-drawer" role="region" aria-label={`${player.name} stats`}>
      <div className="player-drawer-controls">
        <ToggleGroup
          mode="exclusive"
          className="player-drawer-tab"
          wrapperClassName="player-drawer-tabs"
          options={TABS}
          value={tab}
          onChange={(v) => onDrawerChange("tab", v)}
        />
        <div className="player-drawer-actions">
          <ToggleGroup
            mode="exclusive"
            options={[{ value: "raw", label: "Stats" }, { value: "points", label: "Points" }]}
            value={mode}
            onChange={(v) => onDrawerChange("mode", v)}
          />
          {!isLeagueMode && (
            <ToggleGroup
              mode="exclusive"
              options={[{ value: false, label: "Full season" }, { value: true, label: "This pool" }]}
              value={clipped}
              onChange={(v) => onDrawerChange("clipped", v)}
            />
          )}
          {onClose && (
            <IconButton icon={X} label={`Close ${player.name} stats`} onClick={onClose} size={13} />
          )}
        </div>
      </div>

      <div className="player-drawer-summary">
        <span className="player-drawer-summary-score">
          {isLeagueMode
            ? `${TABS.find(t => t.value === tab)?.label} total`
            : effectiveClipped && tab === "season_to_date"
            ? `Season from ${formatDate(player.added_at, { year: "numeric" })}`
            : effectiveClipped
            ? `${TABS.find(t => t.value === tab)?.label} (pool)`
            : `${TABS.find(t => t.value === tab)?.label} total`
          }
        </span>
      </div>

      <div>
        {isLoading && <div className="player-drawer-loading">Loading stats...</div>}
        {isError && <div className="player-drawer-error">Could not load stats</div>}

        {!isLoading && !isError && relevantFields.length === 0 && (
          <div className="player-drawer-empty">No stats recorded yet</div>
        )}

        {!isLoading && !isError && relevantFields.length > 0 && (
          <div className="player-drawer-stat-grid">
            {relevantFields.map(field => (
              <StatRow
                key={field}
                field={field}
                rawValue={periodRaw[field] ?? 0}
                pointValue={periodPoints[field] ?? 0}
                mode={mode}
                label={labels[field] ?? field}
              />
            ))}
            {mode === "points" && (
              <div className="player-drawer-stat-row player-drawer-stat-row--total">
                <span className="player-drawer-stat-label">Total</span>
                <span className="stat-value stat-value--bold">
                  {Number(periodTotal).toFixed(2)}
                </span>
              </div>
            )}
          </div>
        )}
      </div>

      {!isLeagueMode && effectiveClipped && data && player.dropped_at && (
        <div className="player-drawer-clip-notice">
          Dropped {formatDate(player.dropped_at, { year: "numeric" })}
        </div>
      )}
    </div>
  );
}
