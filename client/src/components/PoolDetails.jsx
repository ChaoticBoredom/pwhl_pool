import { useEffect } from 'react'
import { useQuery } from "@tanstack/react-query";
import { useParams, Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext';
import { EditableField } from './EditableField';
import { DataRow } from './DataRow'

function PoolDetails() {
  const { poolId } = useParams()
  const { authHeaders, currentUser } = useAuth();
  const navigate = useNavigate();
  const poolGrid = "grid-cols-[40px_1fr_160px_80px]"

  const { data: pool, isLoading, dataUpdatedAt } = useQuery({
    queryKey: ["pool", poolId],
    queryFn: () => fetch(`/api/pools/${poolId}`, { headers: authHeaders }).then((r) => r.json()),
    staleTime: 25_000,
    refetchInterval: (query) => { return query.state.data?.games_active ? 30_000 : false; },
    gcTime: 5 * 60 * 1000, // 5 minutes to store cached data
  })

  const changePoolName = async (newValue) => {
    const response = await fetch(`/api/pools/${pool.id}`, {
      method: 'PATCH',
      headers: authHeaders,
      body: JSON.stringify({ name: newValue })
    });

    if (!response.ok) {
      console.log("Pool update error:")
    }

    return await response.json()
  }

  useEffect(() => {
    if (pool?.name) {
      document.title = `Fantasy - ${pool.name}`;
    }
  }, [pool]);

  const toOrdinal = (i) => {
    if (isNaN(i)) return;
    const j = i % 10, k = i % 100;
    if (j === 1 && k !== 11) return i + "st";
    if (j === 2 && k !== 12) return i + "nd";
    if (j === 3 && k !== 13) return i + "rd";
    return i + "th";
  };

  if (isLoading || !pool) return <div>Loading pool details...</div>

  const isAdmin = currentUser && pool.admin.id === currentUser;
  const lastFetchedAt = new Date(dataUpdatedAt).toLocaleTimeString();

  return (
    <div>
      <Link to="/" className="back-to-dashboard">← Back to Dashboard</Link>
      <h1 className="text-2xl font-bold my-4">
        {isAdmin ?
          (<EditableField value={pool.name} onSave={changePoolName} />) :
          pool.name}
      </h1>
      <button
        className="btn-primary btn-top"
        onClick={() => navigate(`/pools/${poolId}/scoring`)}
      >
        Scoring Rules
      </button>
      <span className="helper-text">Last Updated At: {lastFetchedAt}</span>
      <div className="mt-6">
        <DataRow isHeader gridClass={poolGrid}>
          <div />
          <div>Team</div>
          <div className="text-right">Owner</div>
          <div className="text-right">Score</div>
        </DataRow>

        {pool.pool_teams?.sort((a, b) => a.rank - b.rank)?.map(team => (
          <DataRow key={team.id} to={`/pools/${poolId}/teams/${team.id}`} gridClass={poolGrid}>
            <div className="font-mono text-xs text-gray-500 tabular-nums">{toOrdinal(team.rank)}</div>
            <div className="font-semibold text-blue-600 truncate">{team.team_name}</div>
            <div className="text-right text-gray-600">{team.user?.name}</div>
            <div className="text-right font-mono font-bold">{team.total_score.toFixed(2)}</div>
          </DataRow>
        ))}
      </div>
    </div>
  )
}

export default PoolDetails
