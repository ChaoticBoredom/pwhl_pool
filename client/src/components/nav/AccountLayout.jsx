import { Outlet } from "react-router-dom";
import NoticeBar from "@c/shared/NoticeBar";
import NoticeFloat from "@c/shared/NoticeFloat";
import NoticeProvider from "@/context/NoticeProvider";
import TopBar from "@c/nav/TopBar";

export default function AccountLayout() {
  return (
    <NoticeProvider>
      <div className="pool-layout">
        <TopBar />
        <NoticeBar />
        <main className="pool-layout__main">
          <Outlet />
        </main>
      </div>
      <NoticeFloat />
    </NoticeProvider>
  );
}
