import { useEffect, useRef } from "react";
import { useSearchParams, useNavigate } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import LoadingState from "@c/shared/LoadingState";

export default function AuthCallback() {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const { login } = useAuth();
  const hasRun = useRef(false);

  useEffect(() => {
    if (hasRun.current) return;
    hasRun.current = true;

    const code = searchParams.get("code");
    if (!code) {
      navigate("/login");
      return;
    }

    fetch("/api/session/exchange", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ code }),
    })
      .then((response) => {
        if (!response.ok) throw new Error("Sign-in failed");
        return response.json();
      })
      .then((result) => {
        login(result.data.user, result.data.token, result.data.god);
        navigate("/");
      })
      .catch(() => navigate("/login?error=oauth_failed"));
  }, [searchParams, navigate, login]);

  return <LoadingState />;
}
