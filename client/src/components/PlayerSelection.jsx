import React, { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import BoxSelection from './BoxSelection'

const PlayerSelection = () => {
  const { poolId, teamId } = useParams();
  const [boxes, setBoxes] = useState([]);
  const { token } = useAuth();
  const navigate = useNavigate();
  const [selections, setSelections] = useState({});
  const [isCurrentSeason, setIsCurrentSeason] = useState(false);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (!poolId) return;
    fetch(`/api/pools/${poolId}/pool_boxes`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    })
    .then(res => res.json()).then(data => {
      setBoxes([...data.boxes].sort((a, b) => a.order - b.order));
      const initial = {};
      data.boxes.forEach(b => {
        const selected = b.players.find(p => p.selected);
        if (selected) initial[b.id] = selected.id;
      });
      setSelections(initial);
      setIsCurrentSeason(!data.using_reference_season);
    })
    .catch(err => console.error("Fetch Error:", err));
  }, [poolId]);

  const handleSubmit = async () => {
    setIsSaving(true);
    const payload = {
      pool_id: poolId,
      new_player_ids: Object.values(selections)
    };

    try {
      const response = await fetch(`/api/pool_teams/${teamId}/update_roster`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify(payload)
      });


      if (response.ok) {
        const data = await response.json();
        const added = data.added_players.join(', ');
        const dropped = data.dropped_players.join(', ');
        alert(`Sucessfully added: ${added}\n\nSuccessfully dropped: ${dropped}`);
        navigate(`/pools/${poolId}/teams/${teamId}`);
      } else if (response.status === 403) {
        alert("You do not have permission to edit this team");
      } else {
        const err = await response.json();
        alert(`Error: ${err.errors?.join(', ') || 'Failed to update'}`);
      }
    } catch (error) {
      console.error("Save failed", error);
    } finally {
      setIsSaving(false);
    }
  };

  const saveButton = (extraClass = "") => (
    <button
      className={`btn-primary ${extraClass}`}
      onClick={handleSubmit}
      disabled={isSaving || Object.keys(selections).length != boxes.length}
    >
      {isSaving ? 'Saving...' : 'Save Roster'}
    </button>
  );

  return (
    <div className="selection-container">
      <header className="selection-header">
        <h1>Select Players</h1>
        {saveButton("btn-top")}
      </header>
      <div className="grid">
        {boxes.map(box => (
          <BoxSelection
            key={box.id}
            box={box}
            isCurrentSeason={isCurrentSeason}
            selectedPlayerId={selections[box.id]}
            onSelect={(playerId) => {
              setSelections({...selections, [box.id]: playerId});
            }}
          />
        ))}
      </div>
      <footer className="selection-footer">
        {saveButton("btn-full")}
        <span className="helper-text">
          Make sure you've selected a player from every box before saving.
        </span>
      </footer>
    </div>
  );
};

export default PlayerSelection
