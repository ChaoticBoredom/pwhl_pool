import { useState } from "react";
import { TradePair } from "./TradePair";

export default function TradeGroup({ teamName, ownerName, requestedAt, status, pairs, onDecide, isDeciding }) {
  const [selected, setSelected] = useState(() => new Set(pairs.map(p => p.poolBoxId)));
  const isPending = status === "pending";

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

  return (
    <div className="trades-panel__group">
      <div className="trades-panel__group-header">
        <div>
          <span className="pool-team-name">{teamName}</span>
          <span className="pool-owner-name"> · {ownerName}</span>
        </div>
        <span className="trades-panel__group-date">{requestedAt}</span>
        {!isPending && (
          <span className={`trade-status-badge trade-status-badge--${status}`}>{status}</span>
        )}
      </div>

      {pairs.map((pair) => (
        <div key={pair.poolBoxId} className="trade-group__pair">
          {isPending && (
            <input
              type="checkbox"
              checked={selected.has(pair.poolBoxId)}
              onChange={() => toggle(pair.poolBoxId)}
            />
          )}
          <TradePair add={pair.add} drop={pair.drop} />
        </div>
      ))}

      {isPending && (
        <div className="trades-panel__cancel-all">
          <button
            className="btn-primary btn-sm"
            disabled={isDeciding || selectedIds.length === 0}
            onClick={() => onDecide("approved", selectedIds)}
          >
            Approve Selected
          </button>
          <button
            className="btn-secondary btn-sm"
            disabled={isDeciding || selectedIds.length === 0}
            onClick={() => onDecide("rejected", selectedIds)}
          >
            Reject Selected
          </button>
        </div>
      )}
    </div>
  );
}
