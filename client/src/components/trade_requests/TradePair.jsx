import TeamBadge from "@c/shared/TeamBadge";

export function TradePair({ add, drop }) {
  return (
    <div className="pending-trade-group__players">
      {drop && (
        <div className="pending-trade-group__player pending-trade-group__player--drop">
          <span className="pending-trade-group__action">Drop</span>
          <span className="pending-trade-group__name">{drop.league_player.name}</span>
          <TeamBadge shortCode={drop.league_player.team_short_code} />
        </div>
      )}
      {add && (
        <div className="pending-trade-group__player pending-trade-group__player--add">
          <span className="pending-trade-group__action">Add</span>
          <span className="pending-trade-group__name">{add.league_player.name}</span>
          <TeamBadge shortCode={add.league_player.team_short_code} />
        </div>
      )}
    </div>
  );
}
