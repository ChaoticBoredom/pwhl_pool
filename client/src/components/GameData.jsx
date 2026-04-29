import { useQuery } from "@tanstack/react-query"
import { useAuth } from "../context/AuthContext";
import { PWHL_TEAMS } from '../constants/teams';

export function GameData({ gameId }) {
  const { authHeaders } = useAuth();

  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ["game-data", gameId],
    queryFn: () => fetch(`/api/games/${gameId}`, { headers: authHeaders }).then(r => r.json()),
    refetchInterval: 30_000,
    enabled: !!gameId,
  });

  const home_team = PWHL_TEAMS[data?.home_team?.short_code] || PWHL_TEAMS['default'];
  const away_team = PWHL_TEAMS[data?.away_team?.short_code] || PWHL_TEAMS['default'];

  const formatGameDate = (timestamp) => {
    if (!timestamp) return "";
    const date = new Date(timestamp);

    const formatter = new Intl.DateTimeFormat('en-US', {
      weekday: "short",
      month: "short",
      day: "numeric",
      hour: "numeric",
      minute: "numeric"
    });

    const parts = formatter.formatToParts(date);

    const weekday = parts.find(p => p.type === 'weekday').value.toUpperCase();
    const month = parts.find(p => p.type === 'month').value;
    const day = parts.find(p => p.type === 'day').value;
    const hour = parts.find(p => p.type === 'hour').value;
    const minute = parts.find(p => p.type === 'minute').value;

    return `${weekday}\n${month} ${day}\n${hour}:${minute}`;
  }

  if (isLoading || !data) return <div />;

  return (
    <div className="player-identity-vertical">
      <span>{formatGameDate(data?.start_time)}</span>
      <div>
        <span 
          className="team-badge-small" 
          style={{ color: away_team.color }}
        >
          {away_team.short}
        </span>
        @
        <span 
          className="team-badge-small" 
          style={{ color: home_team.color }}
        >
          {home_team.short}
        </span>
      </div>
    </div>
  );
}
