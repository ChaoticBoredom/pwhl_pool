import PendingTradeGroup from "@c/trades/PendingTradeGroup";

// Mobile pending trades section — groups requests by pool_box_id
export default function PendingTradesSection({ tradeRequests, boxes, onCancel, isCancelling }) {
  const byBox = tradeRequests.reduce((acc, r) => {
    if (!acc[r.pool_box_id]) acc[r.pool_box_id] = [];
    acc[r.pool_box_id].push(r);
    return acc;
  }, {});

  const boxIds = Object.keys(byBox);
  if (boxIds.length === 0) return null;

  const boxNameById = boxes.reduce((acc, b) => {
    acc[b.id] = b.name;
    return acc;
  }, {});

  return (
    <section className="selection-pending">
      <h2 className="selection-pending__title">Pending Requests</h2>
      {boxIds.map(boxId => (
        <PendingTradeGroup
          key={boxId}
          boxName={boxNameById[boxId] ?? "Unknown Box"}
          requests={byBox[boxId]}
          onCancel={onCancel}
          isCancelling={isCancelling}
        />
      ))}
    </section>
  );
}
