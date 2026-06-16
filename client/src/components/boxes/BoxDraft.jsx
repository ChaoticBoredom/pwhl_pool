import { useState } from "react";
import TeamBadge from "@c/shared/TeamBadge";

export function DraftBox({ box }) {
  const [open, setOpen] = useState(false);
  const players = box.players || [];
  const preview = players.slice(0, 3);

  return (
    <div className="result-box">
      <button className="result-box-header" onClick={() => setOpen(o => !o)}>
        <div className="result-box-title-group">
          <span className="result-box-name">{box.name}</span>
          {!open && (
            <span className="result-box-preview">
              {preview.map(p => p.name).join(", ")}{players.length > 3 ? ` +${players.length - 3}` : ""}
            </span>
          )}
        </div>
        <span className="result-box-count">{players.length} {open ? "▲" : "▼"}</span>
      </button>

      {open && (
        <div className="result-box-players">
          {players.map(player => (
            <div key={player.id} className="player-option result-player-row">
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
          ))}
        </div>
      )}
    </div>
  );
}

const BoxDraft = ({ boxes, usingReferenceSeason, onSave }) => {
  return (
    <section className="generator-section generator-results">
      <div className="generator-section-header">
        <h2>Results</h2>
        {usingReferenceSeason && <span className="reference-season-badge">reference season</span>}
        <button className="btn-primary btn-sm" disabled={!onSave} onClick={onSave}>Save boxes</button>
      </div>
      <div className="result-box-list">
        {boxes.map(box => <DraftBox key={box.name} box={box} />)}
      </div>
    </section>
  );
};

export default BoxDraft;
