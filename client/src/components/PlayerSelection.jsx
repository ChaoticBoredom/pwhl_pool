import React, { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import BoxSelection from './BoxSelection'

const PlayerSelection = () => {
  const { poolId, teamId } = useParams();
  const [boxes, setBoxes] = useState([]);
  const { authHeaders } = useAuth();
  const navigate = useNavigate();
  const [selections, setSelections] = useState({});
  const [isCurrentSeason, setIsCurrentSeason] = useState(false);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (!poolId) return;
    fetch(`/api/pools/${poolId}/pool_boxes`, { headers: authHeaders })
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
    try {
      const response = await fetch(`/api/pool_teams/${teamId}/update_roster`, {
        method: "POST",
        headers: { ...authHeaders, "Accept": "application/json" },
        body: JSON.stringify({ pool_id: poolId, new_player_ids: Object.values(selections) }),
      });

      if (response.ok) {
        const { added_players, dropped_players } = await response.json();
        alert(`Added: ${added_players.join(", ")}\n\nDropped: ${dropped_players.join(", ")}`);
        navigate(`/pools/${poolId}/teams/${teamId}`);
        return;
      }

      if (response.status == 403) {
        const body = await response.json().catch(() => ({}));
        if (!body.reason || body.reason !== "trades_closed") {
          navigate(`/pools/${poolId}`);
          return;
        }
        alert(body.error);
        return;
      }

      const { errors } = await response.json().catch(() => ({}));
      alert(errors?.join(", ") || "Failed to update roster. Please try again.");
    } catch {
      alert("Something went wrong. Please check your connection and try again.");
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
