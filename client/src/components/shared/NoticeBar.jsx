import useNotices from "@/hooks/useNotices";

const ICONS = {
  success: "✓",
  info: "ℹ",
  warning: "⚠",
};

export default function NoticeBar() {
  const { inline, dismiss } = useNotices();

  if (!inline.length) return null;

  return (
    <div className="notice-bar">
      {inline.map((notice) => (
        <div key={notice.id} className={`notice-bar__item notice-bar__item--${notice.severity}`}>
          <span className="notice-bar__icon">{ICONS[notice.severity]}</span>
          <span className="notice-bar__message">
            {notice.message}
            {notice.link && (
              <a href={notice.link.href} className="notice-bar__link">
                {notice.link.label}
              </a>
            )}
          </span>
          <button
            className="notice-bar__dismiss"
            onClick={() => dismiss(notice.id)}
            aria-label="Dismiss"
          >
            ×
          </button>
        </div>
      ))}
    </div>
  );
}
