import { Children } from "react";
import { Link } from "react-router-dom";

function buildGridStyle(columns) {
  return {
    "--data-row-grid": columns.map((c) => c.width).join(" "),
    "--data-row-grid-mobile": columns.filter((c) => !c.hideOnMobile).map((c) => c.width).join(" "),
  };
}

export function DataRow({ to, children, columns = [], isHeader = false, onClick }) {
  const style = buildGridStyle(columns);

  const cells = Children.toArray(children).map((child, i) => {
    if (!columns[i]?.hideOnMobile) return child;
    return <div className="mob-hide-cell" key={child.key ?? i}>{child}</div>;
  });

  const rowClass = isHeader
    ? "data-row data-row--header label-eyebrow label-eyebrow--md"
    : "data-row data-row--content";

  const content = (
    <div onClick={onClick} className={rowClass} style={style}>
      {cells}
    </div>
  );

  return to ? <Link to={to} className="block no-underline">{content}</Link> : content;
}
