import TradesPanel from "@c/trades/TradesPanel";

export default function PendingTradesSection({ tradeRequests, boxes, onCancel, isCancelling }) {
  if (!tradeRequests.length) return null;

  return (
    <section className="selection-pending">
      <h2 className="selection-pending__title">Pending Requests</h2>
      <TradesPanel
        requests={tradeRequests}
        boxes={boxes}
        onCancel={onCancel}
        isCancelling={isCancelling}
      />
    </section>
  );
}
