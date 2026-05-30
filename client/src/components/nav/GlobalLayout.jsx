import { Link, Outlet } from "react-router-dom";
import { Home, UserCircle, User, LogOut } from "lucide-react";
import UserMenu from "./UserMenu";

export default function GlobalLayout() {
  return (
    <div className="pool-layout">
      <header className="top-bar">
        <div className="top-bar__btn" style={{ visibility: "hidden" }}>
          {/* Spacer to keep title centred */}
        </div>

        <div className="top-bar__title" />

        <div className="top-bar__actions">
          <Link to="/" className="top-bar__btn" title="All Pools">
            <Home size={20} />
          </Link>

          <UserMenu />
        </div>
      </header>

      <main className="pool-layout__main">
        <Outlet />
      </main>
    </div>
  );
}
