import TeamBadge from "@c/shared/TeamBadge";

export function TradePair({ add, drop }) {
  return (
    <div className="pending-trade-group__players">
      {drop && (
        <div className="pending-trade-group__player">
          <span className="action-badge action-badge--drop">Drop</span>
          <span className="pending-trade-group__name">{drop.league_player.name}</span>
          <TeamBadge shortCode={drop.league_player.team_short_code} />
        </div>
      )}
      {add && (
        <div className="pending-trade-group__player">
          <span className="action-badge action-badge--add">Add</span>
          <span className="pending-trade-group__name">{add.league_player.name}</span>
          <TeamBadge shortCode={add.league_player.team_short_code} />
        </div>
      )}
    </div>
  );
}
