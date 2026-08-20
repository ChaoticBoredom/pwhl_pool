import { useState } from "react";
import { useSearchParams, useNavigate } from "react-router-dom";
import { useMutation } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";
import NoticeProvider from "@/context/NoticeProvider";
import NoticeFloat from "@c/shared/NoticeFloat";
import useNotices from "@/hooks/useNotices";

function AuthField({ label, ...inputProps }) {
  return (
    <div className="form-field">
      <label className="label-eyebrow label-eyebrow--md">{label}</label>
      <input className="form-input" {...inputProps} />
    </div>
  );
}

// AuthFormInner is separate from AuthForm because useNotices() must run
// inside <NoticeProvider>, and AuthForm is the component providing it —
// a component can't consume the context it's also wrapping itself in.

function AuthFormInner() {
  const [isLogin, setIsLogin] = useState(true);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState("");

  const { login } = useAuth();
  const { add } = useNotices();
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();

  const nextPath = searchParams.get("next") || "/";

  const handleKeyDown = (e) => {
    if (e.key === "Enter") {
      const form = e.target.form;
      const index = [...form.elements].indexOf(e.target);
      const nextElement = form.elements[index + 1];

      if (nextElement && nextElement.tagName === "INPUT") {
        e.preventDefault();
        nextElement.focus();
      }
    }
  };

  const authMutation = useMutation({
    mutationFn: async () => {
      const endpoint = isLogin
        ? "/api/session"
        : "/api/users";

      const payload = isLogin
        ? { email_address: email, password: password }
        : { email_address: email, password: password, name: name };

      const response = await fetch(endpoint, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
        credentials: "include",
      });

      if (!response.ok) throw new Error(isLogin ? "Invalid email or password" : "Could not create account");
      return response.json();
    },
    onSuccess: (result) => {
      login(result.data.user, result.data.token, result.data.god);
      navigate(nextPath);
    },
    onError: (err) => {
      add({ severity: "error", message: err.message });
    },
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    authMutation.mutate();
  };

  return (
    <div className="panel auth-card">
      <h2>{isLogin ? "Login" : "Create Account"}</h2>
      <form onSubmit={handleSubmit} className="stack">
        {!isLogin && (
          <AuthField
            label="Full Name"
            type="text"
            placeholder="Full Name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            onKeyDown={handleKeyDown}
            required
          />
        )}
        <AuthField
          label="Email"
          type="email"
          placeholder="Email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          onKeyDown={handleKeyDown}
          required
        />
        <AuthField
          label="Password"
          type="password"
          placeholder="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
        />
        <button type="submit" className="btn-primary" disabled={authMutation.isPending}>
          {isLogin ? "Sign In" : "Create Account"}
        </button>
      </form>

      <form action="/auth/google_oauth2" method="POST" className="stack">
        <button type="submit" className="btn-secondary">
          Sign in with Google
        </button>
      </form>

      <button onClick={() => setIsLogin(!isLogin)} className="btn-link">
        {isLogin ? "Don't have an account? Sign Up" : "Already have an account? Log In"}
      </button>
    </div>
  );
}

export default function AuthForm() {
  return (
    <NoticeProvider>
      <NoticeFloat />
      <AuthFormInner />
    </NoticeProvider>
  );
}
