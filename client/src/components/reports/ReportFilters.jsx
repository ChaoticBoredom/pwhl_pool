const PERIODS = [
  { value: "day",   label: "Day"   },
  { value: "week",  label: "Week"  },
  { value: "month", label: "Month" },
];

export default function ReportFilters({
  period, onPeriodChange,
  from, onFromChange,
  to, onToChange,
  placeholder = {},
  showPeriod = true,
}) {
  return (
    <div className="rp-controls">
      {showPeriod && (
        <div className="rp-control-group">
          <span className="rp-control-label">Period</span>
          <div className="reports-toggle">
            {PERIODS.map(({ value, label }) => (
              <button
                key={value}
                className={`reports-toggle__btn${period === value ? " reports-toggle__btn--active" : ""}`}
                onClick={() => onPeriodChange(value)}
              >
                {label}
              </button>
            ))}
          </div>
        </div>
      )}

      <div className="rp-control-group">
        <span className="rp-control-label">Date Range</span>
        <div className="reports-date-range">
          <input
            type="date"
            className="reports-date-input"
            value={from}
            placeholder={placeholder.from ?? ""}
            onChange={e => onFromChange(e.target.value)}
          />
          <span className="reports-date-sep">–</span>
          <input
            type="date"
            className="reports-date-input"
            value={to}
            placeholder={placeholder.to ?? ""}
            onChange={e => onToChange(e.target.value)}
          />
          {(from || to) && (
            <button
              className="reports-date-clear"
              onClick={() => { onFromChange(""); onToChange(""); }}
              title="Clear date range"
            >
              ✕
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
