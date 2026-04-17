import React from 'react';
import { PWHL_TEAMS } from '../constants/teams';
import { DataRow } from './DataRow';
import Player from './Player';

const BoxSelection = ({ box, selectedPlayerId, onSelect }) => {
  const selectionGrid = "grid-cols-[1fr_80px]";

  return (
    <div className="box-container mb-6">
      <h3 className="font-bold text-lg border-b pb-2 mb-4">{box.name}</h3>
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
                <span className="score-super">SEASON-TO-DATE</span>
                <span className="score-main">{player.scores.history.season_to_date.toFixed(2)}</span>
              </div>
            </DataRow>
          );
        })}
      </div>
    </div>
  );
};

export default BoxSelection
