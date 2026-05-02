import {
  Trophy, Handshake, Target, Shield, BrickWallShield,
  Medal, Clock, Zap, Gavel, Swords, Star, HelpCircle,
} from "lucide-react"

const STAT_META = {
  goals:               { icon: Trophy,           label: "Goals"               },
  assists:             { icon: Handshake,        label: "Assists"             },
  shots:               { icon: Target,           label: "Shots"               },
  hits:                { icon: Swords,           label: "Hits"                },
  saves:               { icon: Shield,           label: "Saves"               },
  shutout:             { icon: BrickWallShield,  label: "Shutout"             },
  win:                 { icon: Medal,            label: "Win"                 },
  penalty_minutes:     { icon: Clock,            label: "Penalty Minutes"     },
  power_play_goals:    { icon: Zap,              label: "Power Play Goals"    },
  short_handed_goals:  { icon: Gavel,           label: "Short Handed Goals"  },
  faceoffs_won:        { icon: Star,             label: "Faceoffs Won"        },
};

function humanize(field_name) {
  return field_name
    .split("_")
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(" ");
}

function StatCard({ scoring }) {
  const meta = STAT_META[scoring.field_name];
  const Icon = meta?.icon ?? HelpCircle;
  const label = meta?.label ?? humanize(scoring.field_name);

  return (
    <div className="scoring-card">
      <div className="scoring-card-icon">
        <Icon size={18} strokeWidth={1.75} />
      </div>
      <div className="scoring-card-label">{label}</div>
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
