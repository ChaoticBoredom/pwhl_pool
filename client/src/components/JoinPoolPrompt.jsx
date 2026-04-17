import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export default function JoinPoolPrompt() {
  const { poolId } = useParams();
  const navigate = useNavigate();
  const { token, currentUser } = useAuth();
  const [poolName, setPoolName] = useState('Loading...');
  const [teamName, setTeamName] = useState('');
  const [loading, setLoading] = useState(false);
  const [hasTeam, setHasTeam] = useState(false);

  useEffect(() => {
    const fetchPoolData = async () => {
      try {
        const response = await fetch(`${import.meta.env.VITE_API_URL}/pools/${poolId}`, {
          headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
          }
        });

        if (response.ok) {
          const result = await response.json();

          setPoolName(result.name);

          const existingTeam = result.pool_teams?.find(
            team => team.user.id === currentUser
          );

          if (existingTeam) {
            setHasTeam(true);
            console.log("User already has a team, redirecting...");
            navigate(`/pools/${poolId}/teams/${existingTeam.id}`);
          }
        }
      } catch (err) {
        console.error("Pool fetch error:", err);
      }
    };

    if (poolId && currentUser) {
      fetchPoolData();
    }
  }, [poolId, currentUser, navigate, token]);

  const handleJoin = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      const response = await fetch(`${import.meta.env.VITE_API_URL}/pool_teams`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          team: {
            team_name: teamName,
            pool_id: poolId
          }
        })
      });

      if (response.ok) {
        const result = await response.json();

        navigate(`/pools/${poolId}/teams/${result.data.id}/select`)
      } else {
        alert("Error creating team. Please try again.");
      }
    } catch (err) {
      console.error("Team creation error:", err);
    } finally {
      setLoading(false);
    }
  };

  const getButtonText = () => {
    if (hasTeam) return 'Redirecting to your team...';
    if (loading) return 'Creating...';
    return 'Create Team & Pick Players';
  };

  return (
    <div className="card">
      <p>
        You're joining:
      </p>
      <h2>{poolName}</h2>

      <form onSubmit={handleJoin} className="stack">
        <label htmlFor="teamName">Team Name</label>
        <input
          id="teamName"
          type="text"
          placeholder="Enter your team name..."
          value={teamName}
          onChange={(e) => setTeamName(e.target.value)}
          required
          autoFocus
        />
        <button type="submit" className="btn-primary" disabled={loading || hasTeam}>
          {getButtonText()}
        </button>
      </form>
    </div>
  );
}
