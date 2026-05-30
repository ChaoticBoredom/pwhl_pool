import { Link } from "react-router-dom";
import { Menu, Home, User, LogOut, UserCircle } from "lucide-react";
import UserMenu from "./UserMenu";

export default function TopBar({ pool, onMenuToggle }) {
  return (
    <header className="top-bar">
      <button
        className="top-bar__btn"
        onClick={onMenuToggle}
        aria-label="Toggle navigation"
        style={{ visibility: onMenuToggle ? "visible" : "hidden" }}
      >
        <Menu size={20} />
      </button>

      <div className="top-bar__title">
        {pool?.name ?? ""}
      </div>

      <div className="top-bar__actions">
        <Link to="/" className="top-bar__btn" title="All Pools">
          <Home size={20} />
        </Link>
        <UserMenu />
      </div>
    </header>
  );
}
