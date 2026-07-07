import { NavLink } from "react-router-dom";

export default function ReportNav({ poolId }) {
  const base = `/pools/${poolId}/reports`;
  const links = [
    { to: `${base}/standings`, label: "Standings" },
    { to: `${base}/categories`, label: "By Category" },
    { to: `${base}/teams`, label: "Teams" },
  ];

  return (
    <nav className="report-nav">
      {links.map(({ to, label }) => (
        <NavLink
          key={to}
          to={to}
          className={({ isActive }) =>
            `report-nav__link toggle-btn${isActive ? " toggle-btn--active" : ""}`
          }
        >
          {label}
        </NavLink>
      ))}
    </nav>
  );
}
