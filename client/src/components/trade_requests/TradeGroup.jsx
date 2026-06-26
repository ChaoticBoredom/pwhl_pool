import { useState } from "react";
import { formatDateTime } from "@/utils/formatDate";
import { TradePair } from "./TradePair";

export default function TradeGroup({ teamName, ownerName, requestedAt, status, pairs, onDecide, isDeciding }) {
  const [selected, setSelected] = useState(() => new Set(pairs.map(p => p.poolBoxId)));
  const [actionPanel, setActionPanel] = useState(null); // null | "approve" | "reject"
  const [rejectedReason, setRejectedReason] = useState("");
  const [backdatedTo, setBackdatedTo] = useState("");
  const isPending = status === "pending";
  const allSelected = selected.size === pairs.length;
  const someSelected = selected.size > 0 && !allSelected;

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

  const closePanel = () => {
    setActionPanel(null);
    setRejectedReason("");
    setBackdatedTo("");
  };

  const confirmApprove = () => {
    onDecide("approved", selectedIds, { backdated_to: backdatedTo || undefined });
    closePanel();
  };

  const confirmReject = () => {
    if (!rejectedReason.trim()) return;
    onDecide("rejected", selectedIds, { rejected_reason: rejectedReason.trim() });
    closePanel();
  };

  return (
    <div className="trades-panel__group">
      <div className="trades-panel__group-header">
        {isPending && (
          <input
            type="checkbox"
            className="trade-checkbox"
            checked={allSelected}
            ref={(el) => { if (el) el.indeterminate = someSelected; }}
            onChange={toggleAll}
          />
        )}
        <div>
          <span className="pool-team-name">{teamName}</span>
          <span className="pool-owner-name"> · {ownerName}</span>
        </div>
        <span className="trades-panel__group-date">{formatDateTime(requestedAt)}</span>
        <span className={`trade-status-badge trade-status-badge--${status}`}>{status}</span>
      </div>

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
        <div className="trade-group__action-panel">
          <div className="form-field">
            <label className="form-label">Backdate to (optional)</label>
            <input
              type="datetime"
              className="form-input"
              value={backdatedTo}
              onChange={(e) => setBackdatedTo(e.target.value)}
            />
          </div>
          <div className="trade-group__action-buttons">
            <button className="btn-secondary btn-sm" onClick={closePanel} disabled={isDeciding}>
              Cancel
            </button>
            <button className="btn-primary btn-sm" onClick={confirmApprove} disabled={isDeciding}>
              Confirm Approval
            </button>
          </div>
        </div>
      )}

      {actionPanel === "reject" && (
        <div className="trade-group__action-panel">
          <div className="form-field">
            <label className="form-label">Reason for rejection</label>
            <textarea
              className="form-input"
              value={rejectedReason}
              onChange={(e) => setRejectedReason(e.target.value)}
              rows={2}
            />
          </div>
          <div className="trade-group__action-buttons">
            <button className="btn-secondary btn-sm" onClick={closePanel} disabled={isDeciding}>
              Cancel
            </button>
            <button
              className="btn-primary btn-sm"
              onClick={confirmReject}
              disabled={isDeciding || !rejectedReason.trim()}
            >
              Confirm Rejection
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
