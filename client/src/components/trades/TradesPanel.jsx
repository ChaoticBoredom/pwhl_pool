import PendingTradeGroup from "@c/trades/PendingTradeGroup";
import { formatDateTime } from "@/utils/formatDate";

// Groups requests by request_group_id, then by pool_box.id within each group
// Sorts box pairs within a group by pool_box.position
export default function TradesPanel({ requests, boxes, onCancel, isCancelling }) {
  const boxNameById = boxes.reduce((acc, b) => {
    acc[b.id] = b.name;
    return acc;
  }, {});

  const byGroup = requests.reduce((acc, r) => {
    if (!acc[r.request_group_id]) {
      acc[r.request_group_id] = {
        groupId: r.request_group_id,
        requestedAt: r.requested_at,
        byBox: {},
      };
    }
    const boxId = r.pool_box.id;
    if (!acc[r.request_group_id].byBox[boxId]) {
      acc[r.request_group_id].byBox[boxId] = {
        boxId,
        position: r.pool_box.position,
        requests: [],
      };
    }
    acc[r.request_group_id].byBox[boxId].requests.push(r);
    return acc;
  }, {});

  const sortedGroups = Object.values(byGroup).sort(
    (a, b) => new Date(b.requestedAt) - new Date(a.requestedAt),
  );

  return (
    <div className="trades-panel">
      {sortedGroups.map(group => {
        const sortedBoxes = Object.values(group.byBox).sort(
          (a, b) => a.position - b.position,
        );

        return (
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
            {sortedBoxes.map(({ boxId, requests: boxRequests }) => (
              <PendingTradeGroup
                key={boxId}
                boxName={boxNameById[boxId] ?? "Unknown Box"}
                requests={boxRequests}
                onCancel={onCancel}
                isCancelling={isCancelling}
              />
            ))}
          </div>
        );
      })}
    </div>
  );
}
