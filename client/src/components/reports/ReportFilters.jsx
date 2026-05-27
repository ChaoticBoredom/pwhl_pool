import { useState, useEffect } from "react";
import { isValidDate } from "@/utils/reportUtils";

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
  const [localFrom, setLocalFrom] = useState(from);
  const [localTo, setLocalTo] = useState(to);

  // Sync upward only when values are valid or cleared
  useEffect(() => {
    if (localFrom === "" || isValidDate(localFrom)) onFromChange(localFrom);
  }, [localFrom]);

  useEffect(() => {
    if (localTo === "" || isValidDate(localTo)) onToChange(localTo);
  }, [localTo]);

  // Keep local in sync if parent clears
  useEffect(() => { setLocalFrom(from); }, [from]);
  useEffect(() => { setLocalTo(to); }, [to]);

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
            value={localFrom}
            placeholder={placeholder.from ?? ""}
            onChange={e => setLocalFrom(e.target.value)}
          />
          <span className="reports-date-sep">–</span>
          <input
            type="date"
            className="reports-date-input"
            value={localTo}
            placeholder={placeholder.to ?? ""}
            onChange={e => setLocalTo(e.target.value)}
          />
          {(localFrom || localTo) && (
            <button
              className="reports-date-clear"
              onClick={() => { setLocalFrom(""); setLocalTo(""); }}
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
