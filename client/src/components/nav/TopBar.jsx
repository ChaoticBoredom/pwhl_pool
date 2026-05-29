import { useState } from "react";
import { Link, useParams } from "react-router-dom";
import { Menu, X, LogOut, LayoutDashboard } from "lucide-react";
import { useAuth } from "@/context/AuthContext";
import SideNav from "@c/nav/SideNav";

export default function TopBar({ pool, isAdmin }) {
  const { poolId } = useParams();
  const { logout } = useAuth();
  const [mobileOpen, setMobileOpen] = useState(false);

  return (
    <>
      <header className="top-bar">
        {/* Mobile hamburger */}
        <button
          className="top-bar__hamburger"
          onClick={() => setMobileOpen(o => !o)}
          aria-label="Toggle navigation"
        >
          {mobileOpen ? <X size={20} /> : <Menu size={20} />}
        </button>

        {/* Pool name — center on mobile, hidden on desktop (shown in sidebar) */}
        <div className="top-bar__title">
          {pool?.name ?? ""}
        </div>

        <div className="top-bar__actions">
          <Link to="/" className="top-bar__action" title="All Pools">
            <LayoutDashboard size={18} />
          </Link>
          <button className="top-bar__action" onClick={logout} title="Log out">
            <LogOut size={18} />
          </button>
        </div>
      </header>

      {/* Mobile nav drawer */}
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
              onNavigate={() => setMobileOpen(false)}
            />
          </div>
        </>
      )}
    </>
  );
}
