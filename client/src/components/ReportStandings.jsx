import { useState, useMemo } from "react";
import { useParams, Link } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "../context/AuthContext";
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer,
} from "recharts";
import ReportNav from "./ReportNav";
import ReportFilters from "./ReportFilters";
import { teamColour, fmt, periodLabel, ChartTooltip } from "../utils/reportUtils";

export default function ReportStandings() {
  const { poolId } = useParams();
  const { authHeaders } = useAuth();
  const [period, setPeriod] = useState("month");
  const [view, setView] = useState("cumulative");
  const [hiddenIds, setHiddenIds] = useState(new Set());

  const { data: pool } = useQuery({
    queryKey: ["pool", poolId],
    queryFn: () => fetch(`/api/pools/${poolId}`, { headers: authHeaders }).then(r => r.json()),
    staleTime: 60_000,
  });

  const { data, isLoading } = useQuery({
    queryKey: ["reports-trajectory", poolId, period],
    queryFn: () =>
      fetch(`/api/commissioner/${poolId}/reports/score_summary?period=${period}`, { headers: authHeaders })
        .then(r => r.json()),
    staleTime: 60_000,
  });

  const teams = data?.teams ?? [];

  const colourMap = useMemo(() => {
    const map = {};
    teams.forEach(t => { map[t.id] = teamColour(t.id); });
    return map;
  }, [teams]);

  const toggleHidden = (id) => {
    setHiddenIds(prev => {
      const next = new Set(prev);
      next.has(id) ? next.delete(id) : next.add(id);
      return next;
    });
  };

  const sorted = [...teams].sort((a, b) => b.total_score - a.total_score);
  const visibleTeams = teams.filter(t => !hiddenIds.has(t.id));
  const periods = teams[0]?.periods ?? [];

  const chartData = useMemo(() => {
    if (!periods.length) return [];
    const data = periods.map((p, i) => {
      const row = { period: periodLabel(p.from) };
      visibleTeams.forEach(team => { row[team.id] = team.periods[i]?.total_score ?? 0; });
      return row;
    });
    if (view === "cumulative") {
      const running = {};
      data.forEach(row => {
        visibleTeams.forEach(team => {
          running[team.id] = (running[team.id] ?? 0) + (row[team.id] ?? 0);
          row[team.id] = running[team.id];
        });
      });
    }
    return data;
  }, [teams, hiddenIds, view, period]);

  return (
    <div className="app-wrapper">
      <Link to={`/pools/${poolId}`} className="back-to-dashboard">← Back to Pool</Link>
      <div className="rp-header">
        <h1 className="page-title">Season Report</h1>
        {pool && <p className="rp-subtitle">{pool.name}</p>}
      </div>

      <ReportNav poolId={poolId} />
      <ReportFilters period={period} onPeriodChange={setPeriod} />

      {isLoading && <div className="report-loading">Loading…</div>}

      {teams.length > 0 && (
        <div className="rp-layout">
          {/* Standings sidebar */}
          <div className="rp-standings">
            <p className="rp-section-label">Standings</p>
            <div className="standings-list">
              {sorted.map((team, i) => (
                <div
                  key={team.id}
                  className={`standings-row standings-row--toggleable${hiddenIds.has(team.id) ? " standings-row--hidden" : ""}`}
                  onClick={() => toggleHidden(team.id)}
                >
                  <span className="standings-rank">{i + 1}</span>
                  <span className="standings-swatch" style={{ background: colourMap[team.id] }} />
                  <span className="standings-name">{team.team_name}</span>
                  <span className="standings-score">{fmt(team.total_score)}</span>
                </div>
              ))}
            </div>
            {hiddenIds.size > 0 && (
              <button className="standings-reset" onClick={() => setHiddenIds(new Set())}>
                Show all
              </button>
            )}
          </div>

          {/* Trajectory chart */}
          <div className="rp-main">
            <div className="rp-tabs">
              <span className="rp-section-label" style={{ padding: "0.5rem 0.75rem", margin: 0 }}>
                Score Trajectory
              </span>
              <div className="reports-toggle" style={{ marginLeft: "auto" }}>
                {[
                  { value: "cumulative", label: "Cumulative" },
                  { value: "periodic",   label: "Per Period"  },
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
            <div className="rp-chart-area">
              <ResponsiveContainer width="100%" height={340}>
                <LineChart data={chartData} margin={{ top: 8, right: 16, left: 0, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
                  <XAxis dataKey="period" tick={{ fontSize: 11, fill: "var(--text-muted)" }} />
                  <YAxis tick={{ fontSize: 11, fill: "var(--text-muted)" }} width={44} />
                  <Tooltip content={<ChartTooltip />} />
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
          </div>
        </div>
      )}
    </div>
  );
}
