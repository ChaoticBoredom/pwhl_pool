export const teamColour = (id) => {
  const hash = id.split("").reduce((acc, c) => acc + c.charCodeAt(0), 0);
  const hue = (hash * 137.508) % 360;
  return `hsl(${hue}, 65%, 62%)`;
};

export const fmt = (n) => (n == null ? "–" : Number(n).toFixed(2));

export const periodLabel = (from) =>
  new Date(from).toLocaleString("default", { month: "short", year: "2-digit" });

export const ChartTooltip = ({ active, payload, label }) => {
  if (!active || !payload?.length) return null;
  const sorted = [...payload].sort((a, b) => b.value - a.value);
  return (
    <div className="report-tooltip">
      <p className="report-tooltip__label">{label}</p>
      {sorted.map((entry) => (
        <div key={entry.dataKey} className="report-tooltip__row">
          <span className="report-tooltip__swatch" style={{ background: entry.color }} />
          <span className="report-tooltip__team">{entry.name}</span>
          <span className="report-tooltip__value">{fmt(entry.value)}</span>
        </div>
      ))}
    </div>
  );
};
