import { useState, useEffect } from "react";
import { useParams, Outlet } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";
import SideNav from "./SideNav";
import TopBar from "./TopBar";
import NoticeBar from "@c/shared/NoticeBar";
import NoticeFloat from "@c/shared/NoticeFloat";
import NoticeProvider from "@/context/NoticeProvider";
import { useIsMobile } from "@/hooks/useBreakpoint";
import PoolContext from "@/context/PoolContext";

const NAV_COLLAPSED_KEY = "nav_collapsed";

export default function PoolLayout() {
  const { poolId } = useParams();
  const { authHeaders, currentUser, isGod } = useAuth();

  const isMobile = useIsMobile();

  const [collapsed, setCollapsed] = useState(() => {
    if (isMobile) return false;
    return localStorage.getItem(NAV_COLLAPSED_KEY) === "true";
  });
  const [mobileOpen, setMobileOpen] = useState(false);

  useEffect(() => {
    if (!isMobile) localStorage.setItem(NAV_COLLAPSED_KEY, collapsed);
  }, [collapsed, isMobile]);

  const handleMenuToggle = () => {
    if (isMobile) {
      setMobileOpen(o => !o);
    } else {
      setCollapsed(c => !c);
    }
  };

  const { data: pool } = useQuery({
    queryKey: ["pool", poolId],
    queryFn: () =>
      fetch(`/api/pools/${poolId}`, { headers: authHeaders }).then(r => r.json()),
    staleTime: 60_000,
    enabled: !!poolId,
  });

  const isCommissioner = pool && (pool.admin.id === currentUser || isGod);

  return (
    <NoticeProvider>
      <PoolContext.Provider value={{ pool, isCommissioner }}>
        <div className="pool-layout">
          <TopBar pool={pool} onMenuToggle={handleMenuToggle} />
          <NoticeBar />
          <div className="pool-layout__body">
            <SideNav
              poolId={poolId}
              isCommissioner={isCommissioner}
              collapsed={collapsed}
              className="side-nav--desktop"
            />

            {mobileOpen && (
              <>
                <div
                  className="mobile-nav-overlay"
                  onClick={() => setMobileOpen(false)}
                />
                <div className="mobile-nav-drawer">
                  <SideNav
                    poolId={poolId}
                    isCommissioner={isCommissioner}
                    collapsed={false}
                    onNavigate={() => setMobileOpen(false)}
                  />
                </div>
              </>
            )}

              <main className="pool-layout__main">
                <Outlet />
              </main>
          </div>
          <NoticeFloat />
        </div>
      </PoolContext.Provider>
    </NoticeProvider>
  );
}
