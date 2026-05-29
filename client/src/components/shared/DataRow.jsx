import { Link } from "react-router-dom";

export function DataRow({ to, children, gridClass = "", isHeader = false, compact = false, onClick }) {
  const baseClasses = `grid ${gridClass} items-center w-full px-4 ${compact ? "py-1.5" : "py-3"}`;

  if (isHeader) {
    return (
      <div className={`${baseClasses} data-row--header`}>
        {children}
      </div>
    );
  }

  const Content = (
    <div
      onClick={onClick}
      className={`${baseClasses} data-row--content`}>
      {children}
    </div>
  );

  // If 'to' is provided, wrap in a Link; otherwise just show the row
  return to ? <Link to={to} className="block no-underline">{Content}</Link> : Content;
}
