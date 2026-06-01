import useNotices from "@/hooks/useNotices";

export default function NoticeTestPage() {
  const { add, clear } = useNotices();

  return (
    <div style={{ padding: "2rem", display: "flex", flexDirection: "column", gap: "1rem", maxWidth: "400px" }}>
      <h2>Notice System Test</h2>

      <button className="btn-primary btn-sm" onClick={() => add({ severity: "success", message: "Roster saved successfully." })}>
        Success (auto-dismiss)
      </button>

      <button className="btn-primary btn-sm" onClick={() => add({ severity: "info", message: "Trade requests have been approved.", link: { href: "/trades", label: "View trades →" } })}>
        Info with link
      </button>

      <button className="btn-primary btn-sm" onClick={() => add({ severity: "warning", message: "Boxes were updated. Review your selections when you get a chance." })}>
        Warning
      </button>

      <button className="btn-primary btn-sm" onClick={() => add({ severity: "error", message: "Trades are currently locked for this pool." })}>
        Error (floating)
      </button>

      <button className="btn-primary btn-sm" onClick={() => add({
        severity: "action",
        message: "You have pending requests that conflict with this submission. Replace them and continue?",
        dismissable: false,
        actions: [
          { label: "Replace & Submit", onClick: () => console.log("confirmed") },
          { label: "Cancel", variant: "secondary", onClick: () => {}, dismissOnClick: true },
        ],
      })}>
        Action required (floating)
      </button>

      <button className="btn-primary btn-sm" onClick={() => {
        add({ severity: "info", message: "Trade #1 approved." });
        add({ severity: "info", message: "Trade #2 approved." });
        add({ severity: "info", message: "Trade #3 approved." });
        add({ severity: "info", message: "Trade #4 approved — should push oldest off." });
      }}>
        Spam info (cap test)
      </button>

      <button className="btn-link" onClick={clear}>Clear all</button>
    </div>
  );
}
