const PERIODS = [
  { value: "day",   label: "Day"   },
  { value: "week",  label: "Week"  },
  { value: "month", label: "Month" },
];

export default function ReportFilters({ period, onPeriodChange, showPeriod = true }) {
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
    </div>
  );
}
