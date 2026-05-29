import React from "react";
import { DataRow } from "@c/shared/DataRow";
import Player from '@c/players/Player';

const BoxSelection = ({ box, isCurrentSeason, selectedPlayerId, onSelect }) => {
  const selectionGrid = "grid-cols-[1fr_80px]";

  return (
    <div className="box-container mb-6">
      <h3>{box.name}</h3>
      <div className="player-list">
        {box.players.map(player => {
          const isSelected = selectedPlayerId === player.id;

          return (
            <DataRow
              key={player.id}
              gridClass={selectionGrid}
              onClick={() => onSelect(player.id)}
            >
              <Player player={player}>
                <input
                  type="radio"
                  name={`box-${box.id}`}
                  checked={isSelected}
                  onChange={() => onSelect(player.id)}
                />
              </Player>
              <div className="score-display-vertical">
                <span className="score-label">{isCurrentSeason ? "SEASON-TO-DATE" : "LAST SEASON"}</span>
                <span className="score-value">{player.scores.season_to_date.toFixed(2)}</span>
              </div>
            </DataRow>
          );
        })}
      </div>
    </div>
  );
};

export default BoxSelection
