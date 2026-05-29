import { useParams, Link } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from '../context/AuthContext';
import { ScoringSection } from'./ScoringSection';

export default function PoolScoring() {
  const { poolId } = useParams()
  const { authHeaders } = useAuth();

  const { data: scorings, isLoading } = useQuery({
    queryKey: ["pool-scoring", poolId],
    queryFn: () => 
      fetch(`/api/pools/${poolId}/pool_scoring`, { headers: authHeaders })
      .then((r) => r.json()),
    staleTime: 20 * 60 & 1000, // scoring rules rarely change, 20m staletime
  });

  if (isLoading || !scorings) return <div>Loading pool scorings...</div>

  return (
    <div className="selection-container">
      <Link to={`/pools/${poolId}`} className="back-to-dashboard">
        ← Back to Pool
      </Link>
 
      <h2 className="scoring-page-title">Scoring Rules</h2>
 
      <ScoringSection title="Skaters (Forwards and Defense)" scorings={scorings.skaters} />
      <ScoringSection title="Goalies" scorings={scorings.goalies} />
    </div>
  );
}
