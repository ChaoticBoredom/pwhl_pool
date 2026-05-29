import { useState, useMemo } from "react";
import { useParams, Link, useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";
import ReportNav from "./ReportNav";
import ReportFilters from "./ReportFilters";
import CollapsibleStandings from "./CollapsibleStandings";
import TeamBadge from "@c/shared/TeamBadge";
import { fmt, seasonBounds } from "@/utils/reportUtils";
import { buildColourMap } from "@/utils/colourUtils";

function groupByBox(players) {
  const boxes = {};
  players.forEach(p => {
    const boxId = p.pool_box?.id ?? "unassigned";
    if (!boxes[boxId]) {
      boxes[boxId] = {
        box: p.pool_box ?? { id: "unassigned", name: "Unassigned", position: 999 },
        players: {},
      };
    }
    const pid = p.league_player_id;
    if (!boxes[boxId].players[pid]) {
      boxes[boxId].players[pid] = {
        league_player_id: pid,
        name: p.name,
        position: p.position,
        team_short_codes: [],
        tenures: [],
        total_score: 0,
        by_category: {},
        is_active: false,
      };
    }
    const entry = boxes[boxId].players[pid];
    entry.tenures.push({ added_at: p.added_at, dropped_at: p.dropped_at });
    entry.total_score += p.total_score;
    if (!p.dropped_at) entry.is_active = true;
    p.team_short_codes?.forEach(code => {
      if (!entry.team_short_codes.includes(code)) entry.team_short_codes.push(code);
    });
    Object.entries(p.by_category ?? {}).forEach(([k, v]) => {
      entry.by_category[k] = (entry.by_category[k] ?? 0) + v;
    });
  });
  return Object.values(boxes)
    .sort((a, b) => (a.box.position ?? 999) - (b.box.position ?? 999))
    .map(b => ({
      ...b,
      players: Object.values(b.players).sort((a, b) => b.total_score - a.total_score),
    }));
}

const tenureStr = (tenures) =>
  tenures.map(t => {
    const from = new Date(t.added_at).toLocaleDateString("default", { month: "short", day: "numeric" });
    const to = t.dropped_at
      ? new Date(t.dropped_at).toLocaleDateString("default", { month: "short", day: "numeric" })
      : "present";
    return `${from} – ${to}`;
  }).join(" · ");

function TeamDetail({ team, labels, colourMap }) {
  const grouped = useMemo(() => groupByBox(team.by_player ?? []), [team]);

  const keys = useMemo(() => {
    const keySet = new Set();
    (team.by_player ?? []).forEach(p => {
      Object.entries(p.by_category ?? {}).forEach(([k, v]) => { if (v > 0) keySet.add(k); });
    });
    return [...keySet];
  }, [team]);

  return (
    <div className="rp-drilldown">
      <div className="rp-drilldown-header">
        <span className="rp-drilldown-swatch" style={{ background: colourMap[team.id] }} />
        <span className="rp-drilldown-name">{team.team_name}</span>
        <span className="rp-drilldown-total">{fmt(team.total_score)} pts</span>
      </div>

      {grouped.map(({ box, players }) => (
        <div key={box.id} className="rp-box-section">
          <div className="rp-box-header">
            <span className="rp-box-name">{box.name}</span>
            <span className="rp-box-total">
              {fmt(players.reduce((sum, p) => sum + p.total_score, 0))}
            </span>
          </div>

          <div className="rp-player-table" style={{ "--cat-cols": keys.length }}>
            <div className="rp-player-row rp-player-row--header">
              <span>Player</span>
              <span>Tenure</span>
              {keys.map(k => <span key={k} className="rp-cat-cell">{labels?.[k] ?? k}</span>)}
              <span className="rp-cat-cell">Total</span>
            </div>

            {players.map(p => (
              <div
                key={p.league_player_id}
                className={`rp-player-row${!p.is_active ? " rp-player-row--dropped" : ""}`}
              >
                <span className="rp-player-name">
                  {p.name}
                  <span className="rp-team-badges">
                    {p.team_short_codes.map((code, i) => (
                      <span key={code} className="rp-team-badge-wrap">
                        {i > 0 && <span className="rp-team-sep">/</span>}
                        <TeamBadge shortCode={code} />
                      </span>
                    ))}
                  </span>
                  {!p.is_active && <span className="rp-dropped-badge">dropped</span>}
                </span>
                <span className="rp-tenure">{tenureStr(p.tenures)}</span>
                {keys.map(k => (
                  <span key={k} className="rp-cat-cell rp-cat-value">
                    {(p.by_category?.[k] ?? 0) > 0
                      ? fmt(p.by_category[k])
                      : <span className="rp-zero">–</span>}
                  </span>
                ))}
                <span className="rp-cat-cell rp-cat-value rp-cat-total">{fmt(p.total_score)}</span>
              </div>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}

export default function ReportTeams() {
  const { poolId, teamId } = useParams();
  const { authHeaders } = useAuth();
  const navigate = useNavigate();
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
    staleTime: 60 * 60_000,
  });

  const bounds = useMemo(() => seasonBounds(boundsData), [boundsData]);
  const effectiveFrom = from || bounds.from;
  const effectiveTo = to || bounds.to;

  const { data, isLoading } = useQuery({
    queryKey: ["reports-players", poolId, effectiveFrom, effectiveTo],
    queryFn: () => {
      const params = new URLSearchParams();
      params.append("breakdowns[]", "by_player");
      params.append("breakdowns[]", "by_category");
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
  const sorted = useMemo(() => [...teams].sort((a, b) => b.total_score - a.total_score), [teams]);
  const selectedTeam = useMemo(() => teamId ? teams.find(t => t.id === teamId) : null, [teams, teamId]);

  const toggleHidden = (id) => {
    setHiddenIds(prev => {
      const next = new Set(prev);
      next.has(id) ? next.delete(id) : next.add(id);
      return next;
    });
  };

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

      {isLoading && <div className="report-loading">Loading…</div>}

      {teams.length > 0 && (
        selectedTeam ? (
          <div className="rp-full">
            <div className="rp-chart-header">
              <button
                className="back-to-dashboard"
                style={{ margin: 0 }}
                onClick={() => navigate(`/pools/${poolId}/reports/teams`)}
              >
                ← All Teams
              </button>
            </div>
            <TeamDetail team={selectedTeam} labels={labels} colourMap={colourMap} />
          </div>
        ) : (
          <div className="rp-full">
            <div className="rp-team-grid" style={{ padding: "1rem" }}>
              {sorted.map((team, i) => (
                <div
                  key={team.id}
                  className={`rp-team-card${hiddenIds.has(team.id) ? " rp-standings-item--hidden" : ""}`}
                  onClick={() => navigate(`/pools/${poolId}/reports/teams/${team.id}`)}
                >
                  <span className="standings-rank">{i + 1}</span>
                  <span className="rp-team-card-swatch" style={{ background: colourMap[team.id] }} />
                  <span className="rp-team-card-name">{team.team_name}</span>
                  <span className="rp-team-card-score">{fmt(team.total_score)}</span>
                </div>
              ))}
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
        )
      )}
    </div>
  );
}
