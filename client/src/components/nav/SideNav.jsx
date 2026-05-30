import { useState } from "react";
import { NavLink } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import {
  Trophy, Shirt, Star, FileBarChart, BarChart2,
  ArrowLeftRight, Settings, Home,
  ChevronDown, ChevronRight,
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

const ReportsNavCollapsed = ({ base, onNavigate }) => (
  <NavLink
    to={`${base}/reports/standings`}
    className={({ isActive }) =>
      `side-nav__item${isActive ? " side-nav__item--active" : ""}`
    }
    title="Reports"
    onClick={onNavigate}
  >
    <FileBarChart size={18} className="side-nav__icon" />
  </NavLink>
);

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

export default function SideNav({ poolId, pool, isAdmin, collapsed, onNavigate, className = "" }) {
  const { currentUser } = useAuth();
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
          <NavItem to={`${base}/scoring`} icon={Star} label="Scoring" collapsed={collapsed} onClick={onNavigate} />
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

        {isAdmin && (
          <NavSection label="Commissioner" collapsed={collapsed}>
            {collapsed
              ? <ReportsNavCollapsed base={base} onNavigate={onNavigate} />
              : <ReportsNavExpanded base={base} onNavigate={onNavigate} reportsOpen={reportsOpen} setReportsOpen={setReportsOpen} />}
            {/* Coming Soon
            <NavItem to={`${base}/trades`} icon={ArrowLeftRight} label="Trades" collapsed={collapsed} onClick={onNavigate} />
            <NavItem to={`${base}/settings`} icon={Settings} label="Pool Settings" collapsed={collapsed} onClick={onNavigate} />
            */}
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
