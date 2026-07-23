import useNotices from "@/hooks/useNotices";
import { Check, Info, TriangleAlert, X } from "lucide-react";
import IconButton from "@c/shared/IconButton";

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
          <IconButton icon={X} label="Dismiss" onClick={() => dismiss(notice.id)} className="notice-bar__dismiss" size={13} />
        </div>
      ))}
    </div>
  );
}
