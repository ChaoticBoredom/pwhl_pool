import TeamBadge from "@c/shared/TeamBadge";

export default function PendingTradeGroup({ boxName, requests, onCancel, isCancelling }) {
  const drop = requests.find(r => r.action === "drop");
  const add = requests.find(r => r.action === "add");

  return (
    <div className="pending-trade-group">
      <div className="pending-trade-group__header">
        <span className="pending-trade-group__box-name">{boxName}</span>
        <button
          className="btn-primary btn-sm"
          onClick={() => onCancel(requests[0].pool_box_id)}
          disabled={isCancelling}
        >
          Cancel
        </button>
      </div>
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
    </div>
  );
}
