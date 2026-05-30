import { useState, useEffect } from "react";
import { useParams, Outlet } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";
import SideNav from "./SideNav";
import TopBar from "./TopBar";

const NAV_COLLAPSED_KEY = "nav_collapsed";
const MOBILE_BREAKPOINT = 768;

export default function PoolLayout() {
  const { poolId } = useParams();
  const { authHeaders, currentUser, isGod } = useAuth();

  const isMobile = () => window.innerWidth <= MOBILE_BREAKPOINT;

  const [collapsed, setCollapsed] = useState(() => {
    if (isMobile()) return false;
    return localStorage.getItem(NAV_COLLAPSED_KEY) === "true";
  });
  const [mobileOpen, setMobileOpen] = useState(false);

  // Persist collapsed state for desktop only
  useEffect(() => {
    if (!isMobile()) localStorage.setItem(NAV_COLLAPSED_KEY, collapsed);
  }, [collapsed]);

  const handleMenuToggle = () => {
    if (isMobile()) {
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

  const isAdmin = pool && (pool.admin.id === currentUser || isGod);

  return (
    <div className="pool-layout">
      <TopBar pool={pool} onMenuToggle={handleMenuToggle} />
      <div className="pool-layout__body">
        {/* Desktop sidebar */}
        <SideNav
          poolId={poolId}
          pool={pool}
          isAdmin={isAdmin}
          collapsed={collapsed}
          className="side-nav--desktop"
        />

        {/* Mobile drawer overlay */}
        {mobileOpen && (
          <>
            <div
              className="mobile-nav-overlay"
              onClick={() => setMobileOpen(false)}
            />
            <div className="mobile-nav-drawer">
              <SideNav
                poolId={poolId}
                pool={pool}
                isAdmin={isAdmin}
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
    </div>
  );
}
