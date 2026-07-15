import { TradePair } from "@c/shared/TradePair";

export default function CancellableTradePair({ boxName, requests, onCancel, isCancelling }) {
  const drop = requests.find(r => r.action === "drop");
  const add = requests.find(r => r.action === "add");
  const poolBoxId = requests[0].pool_box.id;

  return (
    <div className="pending-trade-group">
      <div className="pending-trade-group__header">
        <span className="pending-trade-group__box-name">{boxName}</span>
        <button
          className="btn-primary btn-sm"
          onClick={() => onCancel({ pool_box_id: poolBoxId })}
          disabled={isCancelling}
        >
          Cancel
        </button>
      </div>
      <TradePair add={add} drop={drop} />
    </div>
  );
}
