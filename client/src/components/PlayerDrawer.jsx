import { useQuery } from "@tanstack/react-query";
import { useAuth } from "../context/AuthContext";
import { X } from "lucide-react";

const TABS = [
  { key: "today", label: "Today" },
  { key: "week_to_date", label: "Week" },
  { key: "month_to_date", label: "Month" },
  { key: "season_to_date", label: "Season" },
];

function formatToi(seconds) {
  if (!seconds) return "0:00";
  return `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, "0")}`;
}

function TabBar({ active, onSelect }) {
  return (
    <div className="player-drawer-tabs" role="tablist">
      {TABS.map(({ key, label }) => (
        <button
          key={key}
          role="tab"
          aria-selected={active === key}
          onClick={() => onSelect(key)}
          className={`player-drawer-tab ${active === key ? "player-drawer-tab--active" : ""}`}
        >
          {label}
        </button>
      ))}
    </div>
  );
}

function ModeToggle({ value, onChange }) {
  return (
    <div className="player-drawer-mode-toggle" role="group" aria-label="Display mode">
      {[
        { key: "raw", label: "Stats"  },
        { key: "points", label: "Points" },
      ].map(({ key, label }) => (
        <button
          key={key}
          onClick={() => onChange(key)}
          className={`player-drawer-mode-btn ${value === key ? "player-drawer-mode-btn--active" : ""}`}
        >
          {label}
        </button>
      ))}
    </div>
  );
}

function ClipToggle({ clipped, onChange }) {
  return (
    <div className="player-drawer-mode-toggle" role="group" aria-label="Stat window">
      {[
        { key: false, label: "Full season" },
        { key: true,  label: "This pool"   },
      ].map(({ key, label }) => (
        <button
          key={String(key)}
          onClick={() => onChange(key)}
          className={`player-drawer-mode-btn ${clipped === key ? "player-drawer-mode-btn--active" : ""}`}
        >
          {label}
        </button>
      ))}
    </div>
  );
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
    display   = pts === 0 ? "—" : `${pts > 0 ? "+" : ""}${Number(pts).toFixed(2)}`;
  }else {
    display = rawValue ?? 0;
  }

  return (
    <div className="player-drawer-stat-row">
      <span className="player-drawer-stat-label">{label}</span>
      <span className={`player-drawer-stat-value ${isDisplayOnly ? "player-drawer-stat-value--dim" : ""}`}>
        {display}
      </span>
    </div>
  );
}

export function PlayerDrawer({ player, isOpen, onClose, drawerState, onDrawerChange }) {
  const { authHeaders } = useAuth();
  const { tab, mode, clipped } = drawerState;

  const { data, isLoading, isError } = useQuery({
    queryKey: ["player-detail", player.id],
    queryFn:  () =>
      fetch(`/api/players/${player.id}/team_player`, { headers: authHeaders })
        .then(r => r.json()),
    enabled:   isOpen,
    staleTime: 5 * 60 * 1000,
  });

  if (!isOpen) return null;

  const labels = data?.labels ?? {};

  const rawSource = clipped ? data?.raw_stats?.clipped_scores : data?.raw_stats?.scores;
  const periodRaw = rawSource?.[tab] ?? {};

  const pointSource = clipped ? data?.expanded_pool_scores?.clipped_scores : data?.expanded_pool_scores?.scores;
  const periodPoints = pointSource?.[tab] ?? {};

  const totalSource  = clipped ? data?.pool_scores?.clipped_scores : data?.pool_scores?.scores;
  const periodTotal  = totalSource?.[tab] ?? 0;

  const relevantFields = Object.keys(data?.raw_stats?.scores?.season_to_date ?? {});

  return (
    <div className="player-drawer" role="region" aria-label={`${player.name} stats`}>

      <div className="player-drawer-controls">
        <TabBar active={tab} onSelect={(v) => onDrawerChange("tab", v)} />
        <div className="player-drawer-actions">
          <ModeToggle value={mode} onChange={(v) => onDrawerChange("mode", v)} />
          <ClipToggle clipped={clipped} onChange={(v) => onDrawerChange("clipped", v)} />
          <button
            onClick={onClose}
            className="player-drawer-close"
            aria-label={`Close ${player.name} stats`}
          >
            <X size={13} />
          </button>
        </div>
      </div>

      <div className="player-drawer-summary">
        <span className="player-drawer-summary-score">
          {clipped && tab === "season_to_date"
            ? `Season from ${new Date(player.added_at).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}`
            : clipped
            ? `${TABS.find(t => t.key === tab)?.label} (pool)`
            : `${TABS.find(t => t.key === tab)?.label} total`
          }
        </span>
      </div>

      <div>
        {isLoading && (
          <div className="player-drawer-loading">Loading stats…</div>
        )}

        {isError && (
          <div className="player-drawer-error">Could not load stats</div>
        )}

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
                <span className="player-drawer-stat-value">
                  {Number(periodTotal).toFixed(2)}
                </span>
              </div>
            )}
          </div>
        )}
      </div>

      {clipped && data && player.dropped_at && (
        <div className="player-drawer-clip-notice">
          Dropped {new Date(player.dropped_at).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}
        </div>
      )}
    </div>
  );
}
