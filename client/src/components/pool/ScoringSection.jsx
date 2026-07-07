import { HelpCircle } from "lucide-react";
import { useLeagueConstants } from "@/constants/useLeagueConstants";

function StatCard({ scoring, editable, onChange }) {
  const { statIconMap } = useLeagueConstants();
  const Icon = statIconMap[scoring.field_name] ?? HelpCircle;

  return (
    <div className={`scoring-card ${!scoring.value ? "scoring-card--unconfigured" : ""}`}>
      <div className="scoring-card-header">
        <div className="scoring-card-icon">
          <Icon size={24} strokeWidth={1.5} />
        </div>
      </div>
      <div className="scoring-card-label">{scoring.descriptive}</div>
      {editable ? (
        <input
          className="scoring-card-input"
          type="number"
          step="0.05"
          value={scoring.value}
          placeholder="0"
          onChange={(e) => onChange(scoring.field_name, scoring.roster_type, e.target.value)}
        />
      ) : (
        <div className="scoring-card-value">
          {scoring.value != null ? scoring.value.toFixed(2) : "—"}
        </div>
      )}
    </div>
  );
}

export function ScoringSection({ title, scorings, editable = false, onChange }) {
  if (!scorings?.length) return null;

  return (
    <div className="scoring-section">
      <div className="scoring-section-title label-eyebrow label-eyebrow--md">{title}</div>
      <div className="scoring-card-grid">
        {scorings.map((scoring) => (
          <StatCard
            key={scoring.field_name}
            scoring={scoring}
            editable={editable}
            onChange={onChange}
          />
        ))}
      </div>
    </div>
  );
}
