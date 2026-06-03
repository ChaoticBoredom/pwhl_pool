import { useContext } from "react";
import { NoticeContext } from "@/context/NoticeContext.js";

export default function useNotices() {
  const ctx = useContext(NoticeContext);
  if (!ctx) throw new Error("useNotices must be used within NoticeProvider");
  return ctx;
}
