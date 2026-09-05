import { useState } from "react";
import { Pencil, Trash2, Check, X } from "lucide-react";
import IconButton from "@c/shared/IconButton";
import { DataRow } from "@c/shared/DataRow";
import { formatDateRange } from "@/utils/formatDate";

const tradeWindowColumns = [
  { width: "1fr" },
  { width: "auto" },
];

function pad(n) {
  return String(n).padStart(2, "0");
}

function formatLocalInputValue(d) {
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

function toLocalInputValue(isoString) {
  if (!isoString) return "";

  return formatLocalInputValue(new Date(isoString));
}

function defaultLocalValue(hours, minutes) {
  const d = new Date();
  d.setHours(hours, minutes, 0, 0);

  return formatLocalInputValue(d);
}

export default function TradeWindowRow({ window, isNew, onSave, onDelete }) {
  const [isEditing, setIsEditing] = useState(isNew);
  const [start, setStart] = useState(isNew ? defaultLocalValue(0, 0) : toLocalInputValue(window?.window_start));
  const [end, setEnd] = useState(isNew ? defaultLocalValue(23, 59) : toLocalInputValue(window?.window_end));
  const [error, setError] = useState(null);
  const [isSaving, setIsSaving] = useState(false);

  const resetToWindow = () => {
    setStart(toLocalInputValue(window?.window_start));
    setEnd(toLocalInputValue(window?.window_end));
    setError(null);
  };

  const handleCancel = () => {
    if (isNew) {
      setStart(defaultLocalValue(0, 0));
      setEnd(defaultLocalValue(23, 59));
      setError(null);
      return;
    }

    resetToWindow();
    setIsEditing(false);
  };

  const handleConfirm = async () => {
    if (!start || !end) {
      setError("Both a start and end are required.");
      return;
    }

    const window_start = new Date(start).toISOString();
    const window_end = new Date(end).toISOString();

    if (window_start >= window_end) {
      setError("Start must be before end.");
      return;
    }

    setError(null);
    setIsSaving(true);

    try {
      await onSave({ window_start, window_end });

      if (isNew) {
        setStart(defaultLocalValue(0, 0));
        setEnd(defaultLocalValue(23, 59));
      } else {
        setIsEditing(false);
      }
    } catch (e) {
      setError(e.message);
    } finally {
      setIsSaving(false);
    }
  };

  if (!isEditing) {
    return (
      <DataRow columns={tradeWindowColumns}>
        <span>{formatDateRange(window.window_start, window.window_end, { year: "numeric" })}</span>
        <div className="box-column__move">
          <IconButton icon={Pencil} label="Edit trade window" onClick={() => setIsEditing(true)} />
          <IconButton icon={Trash2} label="Delete trade window" onClick={onDelete} />
        </div>
      </DataRow>
    );
  }

  return (
    <div className="stack trade-window-row--editing">
      <DataRow columns={tradeWindowColumns}>
        <div className="page-actions">
          <input
            type="datetime-local"
            className="form-input"
            value={start}
            onChange={(e) => setStart(e.target.value)}
          />
          <input
            type="datetime-local"
            className="form-input"
            value={end}
            onChange={(e) => setEnd(e.target.value)}
          />
        </div>

        <div className="box-column__move">
          <IconButton icon={Check} label={isNew ? "Add trade window" : "Save trade window"} onClick={handleConfirm} disabled={isSaving} />
          <IconButton icon={X} label="Cancel" onClick={handleCancel} disabled={isSaving} />
        </div>
      </DataRow>

      {error && <div className="generator-error">{error}</div>}
    </div>
  );
}
