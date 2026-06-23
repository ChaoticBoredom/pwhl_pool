import { useState, useRef } from "react";
import { createPortal } from "react-dom";
import { NavLink } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import { usePool } from "@/context/PoolContext";
import {
  Trophy, Shirt, Star, StarPlus, FileBarChart, BarChart2,
  Home, ChevronDown, ChevronRight, ReplaceAll, SquarePen,
} from "lucide-react";

// eslint-disable-next-line no-unused-vars
const NavItem = ({ to, icon: Icon, label, collapsed, end = false, onClick }) => (
  <NavLink
    to={to}
    end={end}
    onClick={onClick}
    className={({ isActive }) =>
      `side-nav__item${isActive ? " side-nav__item--active" : ""}`
    }
    title={collapsed ? label : undefined}
  >
    <Icon size={18} className="side-nav__icon" />
    {!collapsed && <span className="side-nav__label">{label}</span>}
  </NavLink>
);

const NavSection = ({ label, children, collapsed }) => (
  <div className="side-nav__section">
    {!collapsed && <span className="side-nav__section-label">{label}</span>}
    {collapsed && <div className="side-nav__section-divider" />}
    {children}
  </div>
);

const ReportsNavCollapsed = ({ base, onNavigate }) => {
  const [top, setTop] = useState(null);
  const triggerRef = useRef(null);

  const handleMouseEnter = () => {
    const rect = triggerRef.current?.getBoundingClientRect();
    if (rect) setTop(rect.top);
  };

  return (
    <div
      className="side-nav__popout-wrap"
      onMouseEnter={handleMouseEnter}
      onMouseLeave={() => setTop(null)}
    >
      <div
        ref={triggerRef}
        className="side-nav__item side-nav__item--popout-trigger"
        title="Reports"
      >
        <FileBarChart size={18} className="side-nav__icon" />
      </div>
      {top !== null && createPortal(
        <div className="side-nav__popout" style={{ top }}>
          <span className="side-nav__popout-label">Reports</span>
          <NavItem to={`${base}/reports/standings`} icon={BarChart2} label="Standings" collapsed={false} onClick={onNavigate} />
          <NavItem to={`${base}/reports/categories`} icon={BarChart2} label="Categories" collapsed={false} onClick={onNavigate} />
          <NavItem to={`${base}/reports/teams`} icon={BarChart2} label="Teams" collapsed={false} onClick={onNavigate} />
        </div>,
        document.body
      )}
    </div>
  );
};

const ReportsNavExpanded = ({ base, onNavigate, reportsOpen, setReportsOpen }) => (
  <div className="side-nav__group">
    <button
      className="side-nav__group-toggle"
      onClick={() => setReportsOpen(o => !o)}
    >
      <FileBarChart size={18} className="side-nav__icon" />
      <span className="side-nav__label">Reports</span>
      {reportsOpen
        ? <ChevronDown size={14} className="side-nav__chevron" />
        : <ChevronRight size={14} className="side-nav__chevron" />
      }
    </button>
    {reportsOpen && (
      <div className="side-nav__group-children">
        <NavItem to={`${base}/reports/standings`} icon={BarChart2} label="Standings" collapsed={false} onClick={onNavigate} />
        <NavItem to={`${base}/reports/categories`} icon={BarChart2} label="Categories" collapsed={false} onClick={onNavigate} />
        <NavItem to={`${base}/reports/teams`} icon={BarChart2} label="Teams" collapsed={false} onClick={onNavigate} />
      </div>
    )}
  </div>
);

export default function SideNav({ poolId, collapsed, onNavigate, className = "" }) {
  const { currentUser } = useAuth();
  const { pool, isCommissioner } = usePool();
  const [reportsOpen, setReportsOpen] = useState(false);
  const base = `/pools/${poolId}`;

  const myTeam = pool?.pool_teams?.find(t => t.user?.id === currentUser);

  return (
    <nav className={`side-nav${collapsed ? " side-nav--collapsed" : ""} ${className}`.trim()}>
      <div className="side-nav__content">
        {!collapsed && pool && (
          <div className="side-nav__pool-name">{pool.name}</div>
        )}

        <NavSection label="Pool" collapsed={collapsed}>
          <NavItem to={base} icon={Trophy} label="Standings" collapsed={collapsed} end onClick={onNavigate} />
          <NavItem to={`${base}/scoring`} icon={Star} label="Scoring" collapsed={collapsed} onClick={onNavigate} end />
        </NavSection>

        {myTeam && (
          <NavSection label="My Team" collapsed={collapsed}>
            <NavItem
              to={`${base}/teams/${myTeam.id}`}
              icon={Shirt}
              label="My Team"
              collapsed={collapsed}
              onClick={onNavigate}
            />
          </NavSection>
        )}

        {isCommissioner && (
          <NavSection label="Commissioner" collapsed={collapsed}>
            {collapsed
              ? <ReportsNavCollapsed base={base} onNavigate={onNavigate} />
              : <ReportsNavExpanded base={base} onNavigate={onNavigate} reportsOpen={reportsOpen} setReportsOpen={setReportsOpen} />
            }

            {pool.state !== "completed" && (
              <>
                <NavItem
                  to={`${base}/edit`}
                  icon={SquarePen}
                  label="Edit Pool"
                  collapsed={collapsed}
                  onClick={onNavigate}
                />
                <NavItem
                  to={`${base}/scoring/edit`}
                  icon={StarPlus}
                  label="Edit Scoring"
                  collapsed={collapsed}
                  onClick={onNavigate}
                />
                <NavItem
                  to={`${base}/boxes/edit`}
                  icon={ReplaceAll}
                  label="Edit Boxes"
                  collapsed={collapsed}
                  onClick={onNavigate}
                />
              </>
            )}
          </NavSection>
        )}
      </div>

      <div className="side-nav__footer">
        <NavLink
          to="/"
          className="side-nav__item"
          title={collapsed ? "All Pools" : undefined}
          onClick={onNavigate}
        >
          <Home size={18} className="side-nav__icon" />
          {!collapsed && <span className="side-nav__label">All Pools</span>}
        </NavLink>
      </div>
    </nav>
  );
}
