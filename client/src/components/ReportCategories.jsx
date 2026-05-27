import { useState, useMemo } from "react";
import { useParams, Link } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "../context/AuthContext";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid,
  Tooltip, Legend, ResponsiveContainer,
} from "recharts";
import ReportNav from "./reports/ReportNav";
import ReportFilters from "./reports/ReportFilters";
import ChartTooltip from "./ChartTooltip";
import { teamColour, fmt, seasonBounds } from "../utils/reportUtils";

const CAT_COLOURS = [
  "#c084fc", "#34d399", "#f59e0b", "#60a5fa",
  "#f87171", "#a78bfa", "#4ade80", "#fb923c",
  "#38bdf8", "#e879f9", "#facc15", "#86efac",
];

export default function ReportCategories() {
  const { poolId } = useParams();
  const { authHeaders } = useAuth();
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [hiddenIds, setHiddenIds] = useState(new Set());

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

  const { data, isLoading } = useQuery({
    queryKey: ["reports-category", poolId, effectiveFrom, effectiveTo],
    queryFn: () => {
      const params = new URLSearchParams({ "breakdowns[]": "by_category" });
      if (effectiveFrom) params.set("from", effectiveFrom);
      if (effectiveTo) params.set("to", effectiveTo);
      return fetch(`/api/commissioner/${poolId}/reports/score_summary?${params}`, { headers: authHeaders })
        .then(r => r.json());
    },
    enabled: !!effectiveFrom && !!effectiveTo,
    staleTime: 5 * 60_000,
  });

  const teams  = useMemo(() => data?.teams ?? [], [data]);
  const labels = useMemo(() => data?.labels ?? {}, [data]);

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

  const sorted = useMemo(() => [...teams].sort((a, b) => b.total_score - a.total_score), [teams]);
  const visibleTeams = useMemo(() => teams.filter(t => !hiddenIds.has(t.id)), [teams, hiddenIds]);

  const { keys, chartData } = useMemo(() => {
    const keySet = new Set();
    visibleTeams.forEach(t => {
      Object.entries(t.by_category ?? {}).forEach(([k, v]) => { if (v > 0) keySet.add(k); });
    });
    const keys = [...keySet];
    const chartData = visibleTeams.map(team => ({
      name: team.team_name,
      ...Object.fromEntries(keys.map(k => [k, team.by_category?.[k] ?? 0])),
    }));
    return { keys, chartData };
  }, [visibleTeams]);

  return (
    <div className="app-wrapper">
      <Link to={`/pools/${poolId}`} className="back-to-dashboard">← Back to Pool</Link>
      <div className="rp-header">
        <h1 className="page-title">Season Report</h1>
        {pool && <p className="rp-subtitle">{pool.name}</p>}
      </div>

      <ReportNav poolId={poolId} />
      <ReportFilters
        from={from} onFromChange={setFrom}
        to={to}     onToChange={setTo}
        showPeriod={false}
        placeholder={{ from: bounds.from, to: bounds.to }}
      />

      {isLoading && <div className="report-loading">Loading…</div>}

      {teams.length > 0 && (
        <div className="rp-layout">
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

          <div className="rp-main">
            <div className="rp-tabs">
              <span className="rp-section-label" style={{ padding: "0.5rem 0.75rem", margin: 0 }}>
                Scoring by Category
              </span>
            </div>
            <div className="rp-chart-area">
              {chartData.length > 0 ? (
                <ResponsiveContainer width="100%" height={400}>
                  <BarChart data={chartData} margin={{ top: 8, right: 16, left: 0, bottom: 60 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
                    <XAxis
                      dataKey="name"
                      tick={{ fontSize: 10, fill: "var(--text-muted)" }}
                      angle={-30}
                      textAnchor="end"
                      interval={0}
                    />
                    <YAxis tick={{ fontSize: 11, fill: "var(--text-muted)" }} width={44} />
                    <Tooltip content={<ChartTooltip />} />
                    <Legend
                      formatter={v => labels[v] ?? v}
                      wrapperStyle={{ fontSize: 11, paddingTop: 8 }}
                    />
                    {keys.map((k, i) => (
                      <Bar key={k} dataKey={k} name={labels[k] ?? k}
                        stackId="a" fill={CAT_COLOURS[i % CAT_COLOURS.length]} />
                    ))}
                  </BarChart>
                </ResponsiveContainer>
              ) : (
                <p className="report-loading">No category data.</p>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
