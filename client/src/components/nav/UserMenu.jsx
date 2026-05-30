import { useState, useRef, useEffect } from "react";
import { Link } from "react-router-dom";
import { UserCircle, LogOut } from "lucide-react";
import { useAuth } from "@/context/AuthContext";

export default function UserMenu() {
  const { logout } = useAuth();
  const [open, setOpen] = useState(false);
  const ref = useRef(null);

  useEffect(() => {
    const handler = (e) => {
      if (ref.current && !ref.current.contains(e.target)) setOpen(false);
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  return (
    <div className="top-bar__user-menu" ref={ref}>
      <button className="top-bar__btn" onClick={() => setOpen(o => !o)} aria-label="User menu">
        <UserCircle size={20} />
      </button>
      {open && (
        <div className="top-bar__dropdown">
          {/* <Link to="/profile" className="top-bar__dropdown-item" onClick={() => setOpen(false)}>
            <User size={15} />
            Profile
          </Link>
          <div className="top-bar__dropdown-divider" /> */}
          <button
            className="top-bar__dropdown-item top-bar__dropdown-item--danger"
            onClick={() => { setOpen(false); logout(); }}
          >
            <LogOut size={15} />
            Log out
          </button>
        </div>
      )}
    </div>
  );
}
