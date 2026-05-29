import { useState, useRef, useEffect } from "react";
import { Link, Outlet } from "react-router-dom";
import { Home, UserCircle, User, LogOut } from "lucide-react";
import { useAuth } from "@/context/AuthContext";

export default function GlobalLayout() {
  const { logout } = useAuth();
  const [userMenuOpen, setUserMenuOpen] = useState(false);
  const menuRef = useRef(null);

  useEffect(() => {
    const handler = (e) => {
      if (menuRef.current && !menuRef.current.contains(e.target)) {
        setUserMenuOpen(false);
      }
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

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

          <div className="top-bar__user-menu" ref={menuRef}>
            <button
              className="top-bar__btn"
              onClick={() => setUserMenuOpen(o => !o)}
              aria-label="User menu"
            >
              <UserCircle size={20} />
            </button>

            {userMenuOpen && (
              <div className="top-bar__dropdown">
                <Link
                  to="/profile"
                  className="top-bar__dropdown-item"
                  onClick={() => setUserMenuOpen(false)}
                >
                  <User size={15} />
                  Profile
                </Link>
                <div className="top-bar__dropdown-divider" />
                <button
                  className="top-bar__dropdown-item top-bar__dropdown-item--danger"
                  onClick={() => { setUserMenuOpen(false); logout(); }}
                >
                  <LogOut size={15} />
                  Log out
                </button>
              </div>
            )}
          </div>
        </div>
      </header>

      <main className="pool-layout__main">
        <Outlet />
      </main>
    </div>
  );
}
