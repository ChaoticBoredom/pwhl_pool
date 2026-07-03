import { useState } from "react";
import TeamBadge from "@c/shared/TeamBadge";

function BoxPreviewHeader({ box, open, onToggle }) {
  const players = box.players || [];
  const preview = players.slice(0, 3);

  return (
    <button className="result-box-header" onClick={onToggle}>
      <div className="result-box-title-group">
        <span className="result-box-name">{box.name}</span>
        {!open && (
          <span className="result-box-preview">
            {preview.map((p) => p.name).join(", ")}{players.length > 3 ? ` +${players.length - 3}` : ""}
          </span>
        )}
      </div>
      <span className="result-box-count">{players.length} {open ? "▲" : "▼"}</span>
    </button>
  );
}

function BoxPreviewPlayerRow({ player }) {
  return (
    <div className="player-option result-player-row">
      <div className="player-display-row">
        <div className="player-identity-vertical">
          <span className="player-name">{player.name}</span>
          <TeamBadge shortCode={player.current_team_short_code} />
        </div>
        <div className="score-display-vertical">
          <span className="score-value">{Number(player.score).toFixed(2)}</span>
          <span className="score-label">pts</span>
        </div>
      </div>
    </div>
  );
}

export default function BoxPreview({ box }) {
  const [open, setOpen] = useState(false);
  const players = box.players || [];

  return (
    <div className="panel">
      <BoxPreviewHeader box={box} open={open} onToggle={() => setOpen((o) => !o)} />
      {open && (
        <div className="result-box-players">
          {players.map((player) => <BoxPreviewPlayerRow key={player.id} player={player} />)}
        </div>
      )}
    </div>
  );
}
