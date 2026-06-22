import { useState, useMemo } from "react";
import { useParams, Link } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer,
} from "recharts";
import ReportNav from "./ReportNav";
import ReportFilters from "./ReportFilters";
import ChartTooltip from "@c/shared/ChartTooltip";
import CollapsibleStandings from "./CollapsibleStandings";
import { seasonBounds } from "@/utils/reportUtils";
import { buildColourMap, buildCatColourMap } from "@/utils/colourUtils";
import LoadingState from "@c/shared/LoadingState";

export default function ReportCategories() {
  const { poolId } = useParams();
  const { authHeaders } = useAuth();
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [hiddenIds, setHiddenIds] = useState(new Set());
  const [hiddenCats, setHiddenCats] = useState(new Set());

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
    staleTime: 60 * 60_000,
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
    staleTime: 60 * 60_000,
  });

  const teams = useMemo(() => data?.teams ?? [], [data]);
  const labels = useMemo(() => data?.labels ?? {}, [data]);
  const colourMap = useMemo(() => buildColourMap(teams), [teams]);

  const toggleHidden = (id) => {
    setHiddenIds(prev => {
      const next = new Set(prev);
      next.has(id) ? next.delete(id) : next.add(id);
      return next;
    });
  };

  const toggleCat = (key) => {
    setHiddenCats(prev => {
      const next = new Set(prev);
      next.has(key) ? next.delete(key) : next.add(key);
      return next;
    });
  };

  const visibleTeams = useMemo(() => teams.filter(t => !hiddenIds.has(t.id)), [teams, hiddenIds]);

  // All keys derived from full team list — stable, not affected by hiddenCats
  const allKeys = useMemo(() => {
    const keySet = new Set();
    visibleTeams.forEach(t => {
      Object.entries(t.by_category ?? {}).forEach(([k, v]) => { if (v > 0) keySet.add(k); });
    });
    return [...keySet];
  }, [visibleTeams]);

  // Stable colour map — assigned by position in allKeys, never shifts
  const catColourMap = useMemo(() => buildCatColourMap(allKeys), [allKeys]);

  const chartData = useMemo(() => {
    const visibleKeys = allKeys.filter(k => !hiddenCats.has(k));
    return visibleTeams.map(team => ({
      name: team.team_name,
      ...Object.fromEntries(visibleKeys.map(k => [k, team.by_category?.[k] ?? 0])),
    }));
  }, [visibleTeams, allKeys, hiddenCats]);

  return (
    <div className="app-wrapper">
      <div className="rp-header">
        <h1 className="page-title">Season Report</h1>
        {pool && <p className="rp-subtitle">{pool.name}</p>}
      </div>

      <ReportNav poolId={poolId} />
      <ReportFilters
        key={`${from}-${to}`}
        from={from} onFromChange={setFrom}
        to={to} onToChange={setTo}
        showPeriod={false}
        placeholder={{ from: bounds.from, to: bounds.to }}
      />

      {isLoading && <LoadingState />}

      {teams.length > 0 && (
        <div className="rp-full">
          <div className="rp-chart-header">
            <span className="rp-section-label" style={{ margin: 0 }}>Scoring by Category</span>
          </div>

          <div className="rp-cat-filters">
            {allKeys.map(k => (
              <button
                key={k}
                className={`rp-cat-pill${hiddenCats.has(k) ? " rp-cat-pill--hidden" : ""}`}
                style={{ "--cat-colour": catColourMap[k] }}
                onClick={() => toggleCat(k)}
              >
                {labels[k] ?? k}
              </button>
            ))}
          </div>

          <div className="rp-chart-full">
            {chartData.length > 0 ? (
              <ResponsiveContainer width="100%" height={400}>
                <BarChart data={chartData} margin={{ top: 8, right: 24, left: 0, bottom: 60 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
                  <XAxis
                    dataKey="name"
                    tick={{ fontSize: 10, fill: "var(--text-muted)" }}
                    angle={-30}
                    textAnchor="end"
                    interval={0}
                    tickFormatter={v => v.length > 15 ? `${v.slice(0, 15)}...` : v}
                  />
                  <YAxis tick={{ fontSize: 11, fill: "var(--text-muted)" }} width={44} />
                  <Tooltip content={<ChartTooltip />} />
                  {allKeys.filter(k => !hiddenCats.has(k)).map(k => (
                    <Bar
                      key={k}
                      dataKey={k}
                      name={labels[k] ?? k}
                      stackId="a"
                      fill={catColourMap[k]}
                    />
                  ))}
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <p className="report-empty">No category data.</p>
            )}
          </div>

          <CollapsibleStandings
            teams={teams}
            hiddenIds={hiddenIds}
            onToggle={toggleHidden}
            colourMap={colourMap}
            showActions
            onSelectAll={() => setHiddenIds(new Set())}
            onSelectNone={() => setHiddenIds(new Set(teams.map(t => t.id)))}
          />
        </div>
      )}
    </div>
  );
}
