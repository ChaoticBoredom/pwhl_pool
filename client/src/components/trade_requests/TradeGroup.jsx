import { useState } from "react";
import { formatDateTime, formatDate } from "@/utils/formatDate";
import { useTradeSelection } from "@/hooks/useTradeSelection";
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

function GroupHeader({ selection, team, requestedAt, status }) {
  const { isPending, allSelected, someSelected, onToggleAll } = selection;
  const { name, owner } = team;

  return (
    <div className="mob-trades-panel-header panel__header panel__header--gap-wrap">
      {isPending && (
        <input
          type="checkbox"
          className="trade-checkbox"
          checked={allSelected}
          ref={(el) => { if (el) el.indeterminate = someSelected; }}
          onChange={onToggleAll}
        />
      )}
      <div className="mob-team-info">
        <span className="pool-team-name pool-team-name--clamped">{name}</span>
        <span className="pool-owner-name"> · {owner}</span>
      </div>
      <span className="trades-panel__group-date">{formatDateTime(requestedAt)}</span>
      <span className={`trade-status-badge trade-status-badge--${status}`}>{STATUS_LABELS[status] ?? status}</span>
    </div>
  );
}

function GroupDetails({ backdatedTo, rejectedReason }) {
  return (
    <div className="trade-group__details">
      {backdatedTo && <p className="helper-text">Backdated to {formatDate(backdatedTo)}</p>}
      {rejectedReason && <p className="helper-text">Reason: {rejectedReason}</p>}
    </div>
  );
}

function PairsList({ pairs, isPending, selected, onToggle }) {
  return (
    <>
      {pairs.map((pair) => (
        <div key={pair.poolBoxId} className="trade-group__pair">
          {isPending && (
            <input
              type="checkbox"
              className="trade-checkbox"
              checked={selected.has(pair.poolBoxId)}
              onChange={() => onToggle(pair.poolBoxId)}
            />
          )}
          <TradePair add={pair.add} drop={pair.drop} />
        </div>
      ))}
    </>
  );
}

function ApprovePanel({ effectiveMaxBackdate, onCancel, onConfirm, isDeciding }) {
  const [backdateInput, setBackdateInput] = useState("");

  const handleConfirm = () => {
    onConfirm({ backdated_to: backdateInput || undefined });
  };

  return (
    <ActionPanel onCancel={onCancel} onConfirm={handleConfirm} confirmLabel="Confirm Approval" isDeciding={isDeciding}>
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
  );
}

function RejectPanel({ onCancel, onConfirm, isDeciding }) {
  const [rejectedReason, setRejectedReason] = useState("");

  const handleConfirm = () => {
    if (!rejectedReason.trim()) return;
    onConfirm({ rejected_reason: rejectedReason.trim() });
  };

  return (
    <ActionPanel
      onCancel={onCancel}
      onConfirm={handleConfirm}
      confirmLabel="Confirm Rejection"
      confirmDisabled={!rejectedReason.trim()}
      isDeciding={isDeciding}
    >
      <div className="form-field">
        <label className="label-eyebrow label-eyebrow--md">Reason for rejection</label>
        <textarea className="form-input" value={rejectedReason} onChange={(e) => setRejectedReason(e.target.value)} rows={2} />
      </div>
    </ActionPanel>
  );
}

export default function TradeGroup({ teamName, ownerName, requestedAt, status, pairs, onDecide, isDeciding }) {
  const { selected, allSelected, someSelected, toggleAll, toggle, selectedIds, effectiveMaxBackdate } =
    useTradeSelection(pairs);
  const [actionPanel, setActionPanel] = useState(null); // null | "approve" | "reject"
  const isPending = status === "pending";

  const firstRequest = pairs[0]?.add ?? pairs[0]?.drop;
  const existingBackdatedTo = firstRequest?.backdated_to;
  const existingRejectedReason = firstRequest?.rejected_reason;
  const hasExtraDetails = Boolean(existingBackdatedTo || existingRejectedReason);

  const closePanel = () => setActionPanel(null);

  const confirmApprove = (extra) => {
    onDecide("approved", selectedIds, extra);
    closePanel();
  };

  const confirmReject = (extra) => {
    onDecide("rejected", selectedIds, extra);
    closePanel();
  };

  return (
    <div className="trades-panel__group">
      <GroupHeader
        selection={{ isPending, allSelected, someSelected, onToggleAll: toggleAll }}
        team={{ name: teamName, owner: ownerName }}
        requestedAt={requestedAt}
        status={status}
      />

      {hasExtraDetails && (
        <GroupDetails backdatedTo={existingBackdatedTo} rejectedReason={existingRejectedReason} />
      )}

      <PairsList pairs={pairs} isPending={isPending} selected={selected} onToggle={toggle} />

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
        <ApprovePanel
          effectiveMaxBackdate={effectiveMaxBackdate}
          onCancel={closePanel}
          onConfirm={confirmApprove}
          isDeciding={isDeciding}
        />
      )}

      {actionPanel === "reject" && <RejectPanel onCancel={closePanel} onConfirm={confirmReject} isDeciding={isDeciding} />}
    </div>
  );
}
