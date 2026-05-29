import { Navigate, Outlet, useLocation } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";

export function RequireAuth() {
  const auth = useAuth();
  const location = useLocation();

  if (!auth) return null;

  const { currentUser } = auth;

  if (!currentUser) {
    return (
      <Navigate
        to={`/login?next=${encodeURIComponent(location.pathname)}`}
        replace
      />
    );
  }

  return <Outlet />
}
