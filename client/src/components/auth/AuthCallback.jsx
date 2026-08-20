import { useEffect } from "react";
import { useQuery } from "@tanstack/react-query";
import { useSearchParams, useNavigate } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import LoadingState from "@c/shared/LoadingState";

export default function AuthCallback() {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const { login } = useAuth();
  const code = searchParams.get("code");

  const { data, isError } = useQuery({
    queryKey: ["session-exchange", code],
    queryFn: async () => {
      const response = await fetch("/api/session/exchange", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ code }),
      });
      if (!response.ok) throw new Error("Sign-in failed");
      return response.json();
    },
    enabled: Boolean(code),
    retry: false,
    refetchOnWindowFocus: false,
  });

  useEffect(() => {
    if (!code) {
      navigate("/login");
    } else if (data) {
      login(data.data.user, data.data.token, data.data.god);
      navigate("/");
    } else if (isError) {
      navigate("/login?error=oauth_failed");
    }
  }, [code, data, isError, navigate, login]);

  return <LoadingState />;
}
