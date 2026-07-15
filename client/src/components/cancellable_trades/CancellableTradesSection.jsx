import TradesPanel from "./TradesPanel";

export default function CancellableTradesSection({ tradeRequests, boxes, onCancel, isCancelling }) {
  if (!tradeRequests.length) return null;

  return (
    <section className="selection-pending">
      <h2 className="selection-pending__title label-eyebrow label-eyebrow--lg">Pending Requests</h2>
      <TradesPanel
        requests={tradeRequests}
        boxes={boxes}
        onCancel={onCancel}
        isCancelling={isCancelling}
      />
    </section>
  );
}
