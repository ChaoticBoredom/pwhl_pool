import React from 'react';
import { PWHL_TEAMS } from '../constants/teams';
import Player from './Player';

const BoxSelection = ({ box, selectedPlayerId, onSelect }) => {
  return (
    <div className="box-container">
      <h3>{box.name}</h3>
      <div className="player-list">
        {box.players.map(player => {
          const teamInfo = PWHL_TEAMS[player.current_team_id] || PWHL_TEAMS['default'];

          return (
            <label key={player.id} className={`player-option ${selectedPlayerId === player.id ? 'active' : ''}`}>
              <Player player={player} scoreType="season_to_date">
                <input
                  type="radio"
                  name={`box-${box.id}`}
                  checked={selectedPlayerId === player.id}
                  onChange={() => onSelect(player.id)}
                />
              </Player>
            </label>
          );
        })}
      </div>
    </div>
  );
};

export default BoxSelection