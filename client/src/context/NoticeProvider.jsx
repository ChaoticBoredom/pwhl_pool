import { useCallback, useRef, useState } from "react";
import { NoticeContext } from "@/context/NoticeContext.js";

const AUTO_DISMISS_MS = 10_000;
const INLINE_CAP = 3;

let nextId = 1;

export default function NoticeProvider({ children }) {
  const [inline, setInline] = useState([]);
  const [floating, setFloating] = useState([]);
  const timers = useRef({});

  const dismiss = useCallback((id) => {
    clearTimeout(timers.current[id]);
    delete timers.current[id];
    setInline((prev) => prev.filter((n) => n.id !== id));
    setFloating((prev) => prev.filter((n) => n.id !== id));
  }, []);

  const add = useCallback((notice) => {
    const id = nextId++;
    const entry = { ...notice, id };
    const isFloating = notice.severity === "error" || notice.severity === "action";

    if (isFloating) {
      setFloating((prev) => [...prev, entry]);
    } else {
      setInline((prev) => {
        const next = [entry, ...prev];
        return next.slice(0, INLINE_CAP);
      });

      if (notice.severity === "success") {
        timers.current[id] = setTimeout(() => dismiss(id), AUTO_DISMISS_MS);
      }
    }

    return id;
  }, [dismiss]);

  const clear = useCallback(() => {
    Object.values(timers.current).forEach(clearTimeout);
    timers.current = {};
    setInline([]);
    setFloating([]);
  }, []);

  return (
    <NoticeContext.Provider value={{ inline, floating, add, dismiss, clear }}>
      {children}
    </NoticeContext.Provider>
  );
}
