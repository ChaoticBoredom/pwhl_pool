import { useNotices } from "@/hooks/useNotices";

const ICONS = {
  error: "✕",
  action: "!",
};

export default function NoticeFloat() {
  const { floating, dismiss } = useNotices();

  if (!floating.length) return null;

  return (
    <div className="notice-float">
      {floating.map((notice) => (
        <div key={notice.id} className={`notice-float__item notice-float__item--${notice.severity}`}>
          <div className="notice-float__icon-wrap">
            <span className="notice-float__icon">{ICONS[notice.severity]}</span>
          </div>
          <div className="notice-float__body">
            <p className="notice-float__message">{notice.message}</p>
            {notice.actions && (
              <div className="notice-float__actions">
                {notice.actions.map((action, i) => (
                  <button
                    key={i}
                    className={`notice-float__btn notice-float__btn--${action.variant ?? "primary"}`}
                    onClick={() => {
                      action.onClick();
                      if (action.dismissOnClick !== false) dismiss(notice.id);
                    }}
                  >
                    {action.label}
                  </button>
                ))}
              </div>
            )}
          </div>
          {notice.dismissable !== false && (
            <button
              className="notice-float__close"
              onClick={() => dismiss(notice.id)}
              aria-label="Dismiss"
            >
              ×
            </button>
          )}
        </div>
      ))}
    </div>
  );
}
