import { useState, useEffect, useRef } from "react";
import { isValidDate } from "@/utils/reportUtils";
import { ToggleGroup } from "@c/shared/ToggleGroup";

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
          <ToggleGroup
            mode="exclusive"
            className="toggle-btn"
            options={PERIODS}
            value={period}
            onChange={onPeriodChange}
          />
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
