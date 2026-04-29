import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

export function Dashboard() {
  const { token, authHeaders, logout } = useAuth();
  const [pools, setPools] = useState([]);


  useEffect(() => {
    fetch(`/api/pools`, { headers: authHeaders })
    .then(res => res.json())
    .then(data => setPools(data))
    .catch(err => console.log("Fetch error:", err));
  }, [token])

  return (
    <div>
      <div style={{display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <h1>Dashboard</h1>
        <button onClick={logout}>Logout</button>
      </div>

      <ul>
        {pools.map((pool) => (
          <li key={pool.id} style={{ margin: "10px 0"}}>
            <Link to={`/pools/${pool.id}`} style={{ fontWeight: "bold" }}>
              {pool.name}
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}
