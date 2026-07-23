import useNotices from "@/hooks/useNotices";
import { CircleAlert, CircleX, X } from "lucide-react";
import IconButton from "@c/shared/IconButton";

const ICONS = {
  error: CircleX,
  action: CircleAlert,
};

export default function NoticeFloat() {
  const { floating, dismiss } = useNotices();

  if (!floating.length) return null;

  return (
    <div className="notice-float">
      {floating.map((notice) => {
        const Icon = ICONS[notice.severity];

        return (
          <div key={notice.id} className={`notice-float__item notice-float__item--${notice.severity}`}>
            <span className="notice-float__icon">
              <Icon size={14} />
            </span>
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
              <IconButton icon={X} label="Dismiss" onClick={() => dismiss(notice.id)} className="notice-float__close" size={13} />
            )}
          </div>
        );
      })}
    </div>
  );
}
