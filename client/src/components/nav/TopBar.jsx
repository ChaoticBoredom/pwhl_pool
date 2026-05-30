import { useState, useRef, useEffect } from "react";
import { Link } from "react-router-dom";
import { Menu, Home, User, LogOut, UserCircle } from "lucide-react";
import { useAuth } from "@/context/AuthContext";

export default function TopBar({ pool, onMenuToggle }) {
  const { logout } = useAuth();
  const [userMenuOpen, setUserMenuOpen] = useState(false);
  const menuRef = useRef(null);

  // Close user menu on outside click
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
    <header className="top-bar">
      {/* Left — hamburger */}
      <button
        className="top-bar__btn"
        onClick={onMenuToggle}
        aria-label="Toggle navigation"
      >
        <Menu size={20} />
      </button>

      {/* Centre — pool name (empty on dashboard) */}
      <div className="top-bar__title">
        {pool?.name ?? ""}
      </div>

      {/* Right — home + user menu */}
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
              {/*<Link
                to="/profile"
                className="top-bar__dropdown-item"
                onClick={() => setUserMenuOpen(false)}
              >
                <User size={15} />
                Profile
              </Link>
              <div className="top-bar__dropdown-divider" />*/}
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
  );
}
