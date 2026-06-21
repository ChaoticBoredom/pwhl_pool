import { useParams } from "react-router-dom";
import { useScoringIndex } from "@/hooks/useScoring";
import { useLeagueConstants } from "@/constants/useLeagueConstants";
import { ScoringSection } from "./ScoringSection";
import LoadingState from "@c/shared/LoadingState";

export default function ScoringView() {
  const { poolId } = useParams();
  const { rosterTypeLabels } = useLeagueConstants();
  const { data, isLoading, error } = useScoringIndex(poolId);

  if (isLoading || error) return <LoadingState error={error} />;

  return (
    <div className="app-wrapper">
      <h1 className="scoring-page-title">Scoring Rules</h1>

      {Object.entries(data).
        map(([rosterType, fields]) => (
        <ScoringSection
          key={rosterType}
          title={rosterTypeLabels[rosterType] ?? rosterType}
          scorings={fields.filter((f) => f.value !== 0)}
          editable={false}
        />
      ))}
    </div>
  );
}
