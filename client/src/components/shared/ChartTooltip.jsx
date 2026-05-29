import { fmt } from "@/utils/reportUtils";

export default function ChartTooltip({ active, payload, label }) {
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
}
