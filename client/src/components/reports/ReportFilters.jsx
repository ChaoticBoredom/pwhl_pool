import { useState, useEffect, useRef } from "react";
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

  // Stable refs so effects don't need the callbacks in their dep arrays
  const onFromRef = useRef(onFromChange);
  const onToRef = useRef(onToChange);
  useEffect(() => { onFromRef.current = onFromChange; }, [onFromChange]);
  useEffect(() => { onToRef.current = onToChange; }, [onToChange]);

  useEffect(() => {
    if (localFrom === "" || isValidDate(localFrom)) onFromRef.current(localFrom);
  }, [localFrom]);

  useEffect(() => {
    if (localTo === "" || isValidDate(localTo)) onToRef.current(localTo);
  }, [localTo]);

  return (
    <div className="rp-controls">
      {showPeriod && (
        <div className="rp-control-group">
          <span className="label-eyebrow label-eyebrow--sm">Period</span>
          <div className="reports-toggle">
            {PERIODS.map(({ value, label }) => (
              <button
                key={value}
                className={`reports-toggle__btn toggle-btn${period === value ? " toggle-btn--active" : ""}`}
                onClick={() => onPeriodChange(value)}
              >
                {label}
              </button>
            ))}
          </div>
        </div>
      )}

      <div className="rp-control-group">
        <span className="label-eyebrow label-eyebrow--sm">Date Range</span>
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
