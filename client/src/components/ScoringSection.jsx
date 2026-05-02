import {
  Trophy, Handshake, Target, Shield, BrickWallShield,
  Medal, Clock, Zap, Gavel, Swords, Star, HelpCircle,
} from "lucide-react"

const STAT_ICON_MAP = {
  goals:              Trophy,
  assists:            Handshake,
  shots:              Target,
  hits:               Swords,
  saves:              Shield,
  shutout:            BrickWallShield,
  win:                Medal,
  penalty_minutes:    Clock,
  power_play_goals:   Zap,
  short_handed_goals: Gavel,
  faceoffs_won:       Star,
};

function StatCard({ scoring }) {
  const Icon = STAT_ICON_MAP[scoring.field_name] ?? HelpCircle;

  return (
    <div className="scoring-card">
      <div className="scoring-card-header">
        <div className="scoring-card-icon">
          <Icon size={24} strokeWidth={1.5} />
        </div>
      </div>
      <div className="scoring-card-label">{scoring.descriptive}</div>
      <div className="scoring-card-value">{scoring.value.toFixed(2)}</div>
    </div>
  );
}


export function ScoringSection({ title, scorings }) {
  if (!scorings?.length) return null;

  return (
    <div className="scoring-section">
      <div className="scoring-section-title">{title}</div>
      <div className="scoring-card-grid">
        {scorings.map((scoring) => (
          <StatCard key={scoring.id} scoring={scoring} />
        ))}
      </div>
    </div>
  );
}
