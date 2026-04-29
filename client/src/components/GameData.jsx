import { useQuery } from "@tanstack/react-query"
import { useAuth } from "../context/AuthContext";
import TeamBadge from "./TeamBadge";
import { PWHL_TEAMS } from '../constants/teams';

function Matchup({ away, home, showScore = false })
{
  return (
    <div className="game-matchup">
      <TeamBadge short_code={away.short_code} />
      {showScore && (
        <span className="game-score">{away.score}</span>
      )}
      <span className="game_at">@</span>
      {showScore && (
        <span className="game-score">{home.score}</span>
      )}
      <TeamBadge short_code={home.short_code} />
    </div>
  );
}

function ActivityBar() {
  return (
    <div className="game-activity-track" aria-label="Game in progress">
      <div className="game-activity-bar" />
    </div>
  );
}

function ScheduledGame({ data }) {
  const date = new Date(data.start_time);

  const datePart = new Intl.DateTimeFormat("en-us", {
    weekday: "short",
    month: "short",
    day: "numeric",
  }).format(date);

  const timePart = new Intl.DateTimeFormat("en-US", {
    hour: "numeric",
    minute: "2-digit",
  }).format(date);

  return (
    <div className="game-data">
      <Matchup away={data.away_team} home={data.home_team} />
      <span className="game-meta">{datePart}</span>
      <span className="game-meta">{timePart}</span>
    </div>
  );
}

function InProgressGame({ data }) {
  return (
    <div className="game-data">
      <Matchup away={data.away_team} home={data.home_team} showScore />
      <span className="game-meta game-meta--progress">{data.current_description}</span>
      <ActivityBar />
    </div>
  );
}

function FinishedGame({ data }) {
  return (
    <div className="game-data">
      <Matchup away={data.away_team} home={data.home_team} showScore />
      <span className="game-meta">Final</span>
    </div>
  );
} 

export function GameData({ gameId }) {
  const { authHeaders } = useAuth();

  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ["game-data", gameId],
    queryFn: () => fetch(`/api/games/${gameId}`, { headers: authHeaders }).then(r => r.json()),
    refetchInterval: 30_000,
    enabled: !!gameId,
  });

  if (isLoading || !data) return <div className="game-data game-data--empty" />;

  if (data.status == "in_progress") return <InProgressGame data={data} />;
  if (data.status == "final") return <FinishedGame data={data} />;
  return <ScheduledGame data={data} />
}
