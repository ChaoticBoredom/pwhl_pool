import { useState, useMemo, useRef } from "react";
import { useParams, Link } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "../context/AuthContext";
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer, ReferenceArea,
} from "recharts";
import ReportNav from "./reports/ReportNav";
import ReportFilters from "./reports/ReportFilters";
import ChartTooltip from "./ChartTooltip";
import { buildColourMap, fmt, periodLabel, seasonBounds, isValidDate } from "../utils/reportUtils";

export default function ReportStandings() {
  const { poolId } = useParams();
  const { authHeaders } = useAuth();
  const [period, setPeriod] = useState("month");
  const [view, setView] = useState("cumulative");
  const [hiddenIds, setHiddenIds] = useState(new Set());
  const [standingsOpen, setStandingsOpen] = useState(false);
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");

  // Scrub state
  const [scrubStart, setScrubStart] = useState(null);
  const [scrubEnd, setScrubEnd] = useState(null);
  const isScrubbing = useRef(false);

  const { data: pool } = useQuery({
    queryKey: ["pool", poolId],
    queryFn: () => fetch(`/api/pools/${poolId}`, { headers: authHeaders }).then(r => r.json()),
    staleTime: 60_000,
  });

  const { data: boundsData } = useQuery({
    queryKey: ["reports-bounds", poolId],
    queryFn: () =>
      fetch(`/api/commissioner/${poolId}/reports/score_summary?period=month`, { headers: authHeaders })
        .then(r => r.json()),
    staleTime: 60_000,
  });

  const bounds = useMemo(() => seasonBounds(boundsData), [boundsData]);
  const effectiveFrom = from || bounds.from;
  const effectiveTo = to || bounds.to;
  const isZoomed = !!(from || to);

  const { data, isLoading } = useQuery({
    queryKey: ["reports-trajectory", poolId, period, effectiveFrom, effectiveTo],
    queryFn: () => {
      const params = new URLSearchParams({ period });
      if (effectiveFrom) params.set("from", effectiveFrom);
      if (effectiveTo) params.set("to", effectiveTo);
      return fetch(`/api/commissioner/${poolId}/reports/score_summary?${params}`, { headers: authHeaders })
        .then(r => r.json());
    },
    enabled: !!effectiveFrom && !!effectiveTo,
    staleTime: 60_000,
  });

  const teams = useMemo(() => data?.teams ?? [], [data]);
  const colourMap = useMemo(() => buildColourMap(teams), [teams]);
  const sorted = useMemo(() => [...teams].sort((a, b) => b.total_score - a.total_score), [teams]);
  const visibleTeams = useMemo(() => teams.filter(t => !hiddenIds.has(t.id)), [teams, hiddenIds]);
  const periods = useMemo(() => teams[0]?.periods ?? [], [teams]);

  const toggleHidden = (id) => {
    setHiddenIds(prev => {
      const next = new Set(prev);
      next.has(id) ? next.delete(id) : next.add(id);
      return next;
    });
  };

  const selectAll = () => setHiddenIds(new Set());
  const selectNone = () => setHiddenIds(new Set(teams.map(t => t.id)));

  const resetZoom = () => { setFrom(""); setTo(""); };

  const periodsByLabel = useMemo(() => {
    const map = {};
    periods.forEach(p => {
      map[periodLabel(p.from, data?.period)] = p;
    });
    return map;
  }, [periods, data?.period]);

  const chartData = useMemo(() => {
    if (!periods.length) return [];
    const rows = periods.map((p, i) => {
      const row = { period: periodLabel(p.from, data?.period) };
      visibleTeams.forEach(team => { row[team.id] = team.periods[i]?.total_score ?? 0; });
      return row;
    });
    if (view === "cumulative") {
      const running = {};
      rows.forEach(row => {
        visibleTeams.forEach(team => {
          running[team.id] = (running[team.id] ?? 0) + (row[team.id] ?? 0);
          row[team.id] = running[team.id];
        });
      });
    }
    return rows;
  }, [periods, visibleTeams, view]);

  const handleMouseDown = (e) => {
    if (!e?.activeLabel) return;
    isScrubbing.current = true;
    setScrubStart(e.activeLabel);
    setScrubEnd(e.activeLabel);
  };

  const handleMouseMove = (e) => {
    if (!isScrubbing.current || !e?.activeLabel) return;
    setScrubEnd(e.activeLabel);
  };

  const handleMouseUp = () => {
    if (!isScrubbing.current) return;
    isScrubbing.current = false;

    if (scrubStart && scrubEnd) {
      const startPeriod = periodsByLabel[scrubStart];
      const endPeriod = periodsByLabel[scrubEnd];
      if (startPeriod && endPeriod && startPeriod !== endPeriod) {
        const [a, b] = [startPeriod, endPeriod].sort(
          (x, y) => new Date(x.from) - new Date(y.from)
        );
        setFrom(a.from.slice(0, 10));
        setTo(b.to.slice(0, 10));
      }
    }

    setScrubStart(null);
    setScrubEnd(null);
  };

  const scrubArea = scrubStart
    ? [scrubStart, scrubEnd ?? scrubStart].sort((a, b) => {
        const ai = chartData.findIndex(r => r.period === a);
        const bi = chartData.findIndex(r => r.period === b);
        return ai - bi;
      })
    : null;

  return (
    <div className="app-wrapper">
      <Link to={`/pools/${poolId}`} className="back-to-dashboard">← Back to Pool</Link>
      <div className="rp-header">
        <h1 className="page-title">Season Report</h1>
        {pool && <p className="rp-subtitle">{pool.name}</p>}
      </div>

      <ReportNav poolId={poolId} />
      <ReportFilters
        period={period} onPeriodChange={setPeriod}
        from={from} onFromChange={setFrom}
        to={to} onToChange={setTo}
        placeholder={{ from: bounds.from, to: bounds.to }}
      />

      {isLoading && <div className="report-loading">Loading…</div>}

      {teams.length > 0 && (
        <div className="rp-full">
          {/* Chart header */}
          <div className="rp-chart-header">
            <span className="rp-section-label" style={{ margin: 0 }}>Score Trajectory</span>
            <div className="rp-chart-controls">
              {isZoomed && (
                <button className="rp-reset-zoom" onClick={resetZoom}>
                  Reset Zoom
                </button>
              )}
              <div className="reports-toggle">
                {[
                  { value: "cumulative", label: "Cumulative" },
                  { value: "periodic", label: "Per Period" },
                ].map(({ value, label }) => (
                  <button
                    key={value}
                    className={`reports-toggle__btn${view === value ? " reports-toggle__btn--active" : ""}`}
                    onClick={() => setView(value)}
                  >
                    {label}
                  </button>
                ))}
              </div>
            </div>
          </div>

          {/* Full-width chart */}
          <div className="rp-chart-full">
            <ResponsiveContainer width="100%" height={400}>
              <LineChart
                data={chartData}
                margin={{ top: 8, right: 24, left: 0, bottom: 0 }}
                onMouseDown={handleMouseDown}
                onMouseMove={handleMouseMove}
                onMouseUp={handleMouseUp}
                style={{ userSelect: "none" }}
              >
                <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
                <XAxis dataKey="period" tick={{ fontSize: 11, fill: "var(--text-muted)" }} />
                <YAxis tick={{ fontSize: 11, fill: "var(--text-muted)" }} width={44} />
                <Tooltip content={<ChartTooltip />} />
                {scrubArea && (
                  <ReferenceArea
                    x1={scrubArea[0]}
                    x2={scrubArea[1]}
                    fill="var(--accent)"
                    fillOpacity={0.15}
                    stroke="var(--accent)"
                    strokeOpacity={0.4}
                  />
                )}
                {visibleTeams.map(team => (
                  <Line
                    key={team.id}
                    type="monotone"
                    dataKey={team.id}
                    name={team.team_name}
                    stroke={colourMap[team.id]}
                    strokeWidth={2}
                    dot={{ r: 3 }}
                    activeDot={{ r: 5 }}
                  />
                ))}
              </LineChart>
            </ResponsiveContainer>
          </div>

          {/* Collapsible standings */}
          <div className="rp-standings-bar">
            <button
              className="rp-standings-toggle"
              onClick={() => setStandingsOpen(o => !o)}
            >
              <span className="rp-section-label" style={{ margin: 0 }}>
                Standings ({teams.length} teams)
              </span>
              <span className="rp-standings-chevron">{standingsOpen ? "▲" : "▼"}</span>
            </button>

            {standingsOpen && (
              <>
                <div className="rp-standings-actions">
                  <button className="btn-primary btn-sm" onClick={selectAll}>Select All</button>
                  <button className="btn-primary btn-sm" onClick={selectNone}>Select None</button>
                </div>
                <div className="rp-standings-grid">
                  {sorted.map((team, i) => (
                    <div
                      key={team.id}
                      className={`rp-standings-item${hiddenIds.has(team.id) ? " rp-standings-item--hidden" : ""}`}
                      onClick={() => toggleHidden(team.id)}
                    >
                      <span className="standings-rank">{i + 1}</span>
                      <span className="standings-swatch" style={{ background: colourMap[team.id] }} />
                      <span className="rp-standings-item-name">{team.team_name}</span>
                      <span className="standings-score">{fmt(team.total_score)}</span>
                    </div>
                  ))}
                </div>
              </>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
