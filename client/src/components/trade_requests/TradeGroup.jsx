import { useState } from "react";
import { formatDateTime, formatDate } from "@/utils/formatDate";
import { TradePair } from "./TradePair";

const STATUS_LABELS = {
  pending: "Pending",
  approved: "Approved",
  auto_approved: "Auto-Approved",
  rejected: "Rejected",
  auto_rejected: "Auto-Rejected",
  cancelled: "Cancelled",
  auto_cancelled: "Auto-Cancelled",
};

function ActionPanel({ onCancel, onConfirm, confirmLabel, confirmDisabled, isDeciding, children }) {
  return (
    <div className="trade-group__action-panel">
      {children}
      <div className="trade-group__action-buttons">
        <button className="btn-secondary btn-sm" onClick={onCancel} disabled={isDeciding}>
          Cancel
        </button>
        <button className="btn-primary btn-sm" onClick={onConfirm} disabled={isDeciding || confirmDisabled}>
          {confirmLabel}
        </button>
      </div>
    </div>
  );
}

export default function TradeGroup({ teamName, ownerName, requestedAt, status, pairs, onDecide, isDeciding }) {
  const [selected, setSelected] = useState(() => new Set(pairs.map(p => p.poolBoxId)));
  const [actionPanel, setActionPanel] = useState(null); // null | "approve" | "reject"
  const [rejectedReason, setRejectedReason] = useState("");
  const [backdateInput, setBackdateInput] = useState("");
  const [detailsOpen, setDetailsOpen] = useState(false);
  const isPending = status === "pending";
  const allSelected = selected.size === pairs.length;
  const someSelected = selected.size > 0 && !allSelected;

  const firstRequest = pairs[0]?.add ?? pairs[0]?.drop;
  const existingBackdatedTo = firstRequest?.backdated_to;
  const existingRejectedReason = firstRequest?.rejected_reason;
  const hasExtraDetails = Boolean(existingBackdatedTo || existingRejectedReason);

  const toggleAll = () => {
    setSelected(allSelected ? new Set() : new Set(pairs.map(p => p.poolBoxId)));
  };

  const toggle = (poolBoxId) => {
    setSelected(prev => {
      const next = new Set(prev);
      next.has(poolBoxId) ? next.delete(poolBoxId) : next.add(poolBoxId);
      return next;
    });
  };

  const selectedIds = pairs
    .filter(p => selected.has(p.poolBoxId))
    .flatMap(p => [p.add?.id, p.drop?.id])
    .filter(Boolean);

  const selectedMaxBackdates = pairs
    .filter((p) => selected.has(p.poolBoxId))
    .map((p) => p.maxBackdate)
    .filter(Boolean);

  const effectiveMaxBackdate = selectedMaxBackdates.length
    ? selectedMaxBackdates.reduce((min, d) => (d < min ? d : min))
    : null;

  const closePanel = () => {
    setActionPanel(null);
    setRejectedReason("");
    setBackdateInput("");
  };

  const confirmApprove = () => {
    onDecide("approved", selectedIds, { backdated_to: backdateInput || undefined });
    closePanel();
  };

  const confirmReject = () => {
    if (!rejectedReason.trim()) return;
    onDecide("rejected", selectedIds, { rejected_reason: rejectedReason.trim() });
    closePanel();
  };

  return (
    <div className="trades-panel__group">
      <div className="mob-trades-panel-header panel__header panel__header--gap-wrap">
        {isPending && (
          <input
            type="checkbox"
            className="trade-checkbox"
            checked={allSelected}
            ref={(el) => { if (el) el.indeterminate = someSelected; }}
            onChange={toggleAll}
          />
        )}
        <div className="mob-team-info">
          <span className="pool-team-name pool-team-name--clamped">{teamName}</span>
          <span className="pool-owner-name"> · {ownerName}</span>
        </div>
        <span className="trades-panel__group-date">{formatDateTime(requestedAt)}</span>
        <span className={`trade-status-badge trade-status-badge--${status}`}>{STATUS_LABELS[status] ?? status}</span>
        {hasExtraDetails && (
          <button
            className="box-selection__expand-btn"
            onClick={() => setDetailsOpen((o) => !o)}
          >
            Details {detailsOpen ? "▲" : "▼"}
          </button>
        )}
      </div>

      {detailsOpen && hasExtraDetails && (
        <div className="trade-group__details">
          {existingBackdatedTo && (
            <p className="helper-text">Backdated to {formatDate(existingBackdatedTo)}</p>
          )}
          {existingRejectedReason && (
            <p className="helper-text">Reason: {existingRejectedReason}</p>
          )}
        </div>
      )}

      {pairs.map((pair) => (
        <div key={pair.poolBoxId} className="trade-group__pair">
          {isPending && (
            <input
              type="checkbox"
              className="trade-checkbox"
              checked={selected.has(pair.poolBoxId)}
              onChange={() => toggle(pair.poolBoxId)}
            />
          )}
          <TradePair add={pair.add} drop={pair.drop} />
        </div>
      ))}

      {isPending && actionPanel === null && (
        <div className="trades-panel__cancel-all">
          <button
            className="btn-primary btn-sm"
            disabled={isDeciding || selectedIds.length === 0}
            onClick={() => setActionPanel("approve")}
          >
            Approve Selected
          </button>
          <button
            className="btn-secondary btn-sm"
            disabled={isDeciding || selectedIds.length === 0}
            onClick={() => setActionPanel("reject")}
          >
            Reject Selected
          </button>
        </div>
      )}

      {actionPanel === "approve" && (
        <ActionPanel
          onCancel={closePanel}
          onConfirm={confirmApprove}
          confirmLabel="Confirm Approval"
          isDeciding={isDeciding}
        >
          <div className="form-field">
            <label className="label-eyebrow label-eyebrow--md">Backdate to (optional)</label>
            <input
              type="date"
              className="form-input"
              value={backdateInput}
              min={effectiveMaxBackdate?.slice(0, 10)}
              onChange={(e) => setBackdateInput(e.target.value)}
            />
          </div>
        </ActionPanel>
      )}

      {actionPanel === "reject" && (
        <ActionPanel
          onCancel={closePanel}
          onConfirm={confirmReject}
          confirmLabel="Confirm Rejection"
          confirmDisabled={!rejectedReason.trim()}
          isDeciding={isDeciding}
        >
          <div className="form-field">
            <label className="label-eyebrow label-eyebrow--md">Reason for rejection</label>
            <textarea
              className="form-input"
              value={rejectedReason}
              onChange={(e) => setRejectedReason(e.target.value)}
              rows={2}
            />
          </div>
        </ActionPanel>
      )}
    </div>
  );
}
