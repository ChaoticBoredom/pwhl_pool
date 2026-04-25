import { useEffect, useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { useAuth } from '../context/AuthContext';
import { DataRow } from './DataRow';
import { ScoringSection } from'./ScoringSection';

export default function PoolScoring() {
  const { poolId } = useParams()
  const [scorings, setScorings] = useState(null)
  const { token, currentUser } = useAuth();
  const poolGrid = "grid-cols-[minmax(240px,1fr)_80px]"

  useEffect(() => {
    fetch(`/api/pools/${poolId}/pool_scoring`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    })
    .then(res => res.json())
    .then(data => setScorings(data))
    .catch(err => console.error("Error fetching pool scoring:", err))
  }, [poolId, token])

  if (!scorings) return <div>Loading pool scorings...</div>

  return (
    <div className="selection-container">
      <div className="mt-6">
        <DataRow isHeader gridClass={poolGrid}>
          <div>Stat</div>
          <div className="text-right">Value</div>
        </DataRow>

        <ScoringSection title="Skaters (Forwards and Defense)" scorings={scorings?.skaters} poolGrid={poolGrid} />
        <ScoringSection title="Goalies" scorings={scorings?.goalies} poolGrid={poolGrid} />
      </div>
    </div>
  );
}
