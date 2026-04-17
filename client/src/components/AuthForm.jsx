import { useState } from 'react'
import { useSearchParams, useNavigate } from 'react-router-dom'
import { useAuth } from  '../context/AuthContext'

export default function AuthForm() {
  const [isLogin, setIsLogin] = useState(true);
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [name, setName] = useState('')

  const  { login } = useAuth();
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();

  const nextPath = searchParams.get('next') || '/';

  const handleKeyDown = (e) => {
    if (e.key === 'Enter') {
      const form = e.target.form;
      const index = [...form.elements].indexOf(e.target);
      const nextElement = form.elements[index + 1];

      if (nextElement && nextElement.tagName === 'INPUT') {
        e.preventDefault();
        nextElement.focus();
      }
    }
  }

  const handleSubmit = async (e) => {
    e.preventDefault()

    const endpoint = isLogin
      ? `${import.meta.env.VITE_API_URL}/session`
      : `${import.meta.env.VITE_API_URL}/users`;

    const payload = isLogin
      ? { email_address: email, password: password }
      : { email_address: email, password: password, name: name };

    try {
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
        credentials: 'include'
      })

      if (response.ok) {
        const result = await response.json()
        login(result.data.user, result.data.token);
        navigate(nextPath);
      } else {
        alert(isLogin ? "Invalid email or password" : "Could not create account");
      }
    } catch (err) {
      console.error("Auth error:", err);
    }
  };

  return (
    <div className="card">
      <h2>{isLogin ? 'Login' : 'Create Account'}</h2>
      <form onSubmit={handleSubmit} className="stack">
        {!isLogin && (
          <input
            type="text"
            placeholder="Full Name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            onKeyDown={handleKeyDown}
            required
          />
        )}
        <input
          type="email"
          placeholder="Email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          onKeyDown={handleKeyDown}
          required
        />
        <input
          type="password"
          placeholder="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
        />
        <button type="submit" className="btn-primary">
          {isLogin ? 'Sign In' : 'Join League'}
        </button>
      </form>

      <button onClick={() => setIsLogin(!isLogin)} className="btn-link">
        {isLogin ? "Don't have an account? Sign Up" : "Already have an account? Log In"}
      </button>
    </div>
  );
}
