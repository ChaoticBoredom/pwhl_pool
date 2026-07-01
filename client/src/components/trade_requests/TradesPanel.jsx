import PendingTradeGroup from "./PendingTradeGroup";
import { groupTradeRequests } from "@/utils/groupTradeRequests";
import { formatDateTime } from "@/utils/formatDate";

export default function TradesPanel({ requests, boxes, onCancel, isCancelling }) {
  const groups = groupTradeRequests(requests, boxes);

  return (
    <div className="trades-panel">
      {groups.map((group) => (
        <div key={group.groupId} className="trades-panel__group">
          <div className="trades-panel__group-header">
            <span className="trades-panel__group-date">
              Submitted {formatDateTime(group.requestedAt)}
            </span>
            <button
              className="btn-primary btn-sm trades-panel__cancel-all"
              onClick={() => onCancel({ request_group_id: group.groupId })}
              disabled={isCancelling}
            >
              Cancel Trades
            </button>
          </div>
          {group.pairs.map((pair) => (
            <PendingTradeGroup
              key={pair.poolBoxId}
              boxName={pair.boxName ?? "Unknown Box"}
              requests={[pair.add, pair.drop].filter(Boolean)}
              onCancel={onCancel}
              isCancelling={isCancelling}
            />
          ))}
        </div>
      ))}
    </div>
  );
}
