import { useState, useEffect } from "react";
import { NavLink, useParams } from "react-router-dom";
import {
  Trophy, Shirt, BarChart2, Star, FileBarChart,
  ArrowLeftRight, Settings, LayoutDashboard,
  PanelLeftClose, PanelLeftOpen, ChevronDown, ChevronRight,
} from "lucide-react";

const NAV_COLLAPSED_KEY = "nav_collapsed";

const NavItem = ({ to, icon: Icon, label, collapsed, end = false }) => (
  <NavLink
    to={to}
    end={end}
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
    {!collapsed && (
      <span className="side-nav__section-label">{label}</span>
    )}
    {collapsed && <div className="side-nav__section-divider" />}
    {children}
  </div>
);

export default function SideNav({ poolId, pool, isAdmin }) {
  const [collapsed, setCollapsed] = useState(() => {
    return localStorage.getItem(NAV_COLLAPSED_KEY) === "true";
  });
  const [reportsOpen, setReportsOpen] = useState(false);

  useEffect(() => {
    localStorage.setItem(NAV_COLLAPSED_KEY, collapsed);
  }, [collapsed]);

  const base = `/pools/${poolId}`;

  return (
    <nav className={`side-nav${collapsed ? " side-nav--collapsed" : ""}`}>
      <div className="side-nav__content">
        {/* Pool name */}
        {!collapsed && pool && (
          <div className="side-nav__pool-name">{pool.name}</div>
        )}

        <NavSection label="Pool" collapsed={collapsed}>
          <NavItem to={base} icon={Trophy} label="Standings" collapsed={collapsed} end />
          <NavItem to={`${base}/scoring`} icon={Star} label="Scoring" collapsed={collapsed} />
        </NavSection>

        <NavSection label="My Team" collapsed={collapsed}>
          <NavItem
            to={pool?.pool_teams ? `${base}/teams/${pool.pool_teams.find(t => t.user?.id)?.id}` : base}
            icon={Shirt}
            label="My Team"
            collapsed={collapsed}
          />
        </NavSection>

        {isAdmin && (
          <NavSection label="Commissioner" collapsed={collapsed}>
            {/* Reports — collapsible when expanded, single item when collapsed */}
            {collapsed ? (
              <NavLink
                to={`${base}/reports/standings`}
                className={({ isActive }) =>
                  `side-nav__item${isActive ? " side-nav__item--active" : ""}`
                }
                title="Reports"
              >
                <FileBarChart size={18} className="side-nav__icon" />
              </NavLink>
            ) : (
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
                    <NavItem to={`${base}/reports/standings`} icon={BarChart2} label="Standings" collapsed={false} />
                    <NavItem to={`${base}/reports/categories`} icon={BarChart2} label="Categories" collapsed={false} />
                    <NavItem to={`${base}/reports/teams`} icon={BarChart2} label="Teams" collapsed={false} />
                  </div>
                )}
              </div>
            )}

            <NavItem to={`${base}/trades`} icon={ArrowLeftRight} label="Trades" collapsed={collapsed} />
            <NavItem to={`${base}/settings`} icon={Settings} label="Pool Settings" collapsed={collapsed} />
          </NavSection>
        )}
      </div>

      <div className="side-nav__footer">
        <NavLink to="/" className="side-nav__item" title={collapsed ? "All Pools" : undefined}>
          <LayoutDashboard size={18} className="side-nav__icon" />
          {!collapsed && <span className="side-nav__label">All Pools</span>}
        </NavLink>
        <button
          className="side-nav__collapse-btn"
          onClick={() => setCollapsed(c => !c)}
          title={collapsed ? "Expand" : "Collapse"}
        >
          {collapsed
            ? <PanelLeftOpen size={18} />
            : <PanelLeftClose size={18} />
          }
        </button>
      </div>
    </nav>
  );
}
