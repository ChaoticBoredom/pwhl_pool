import React, { useEffect, useMemo, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useQuery } from "@tanstack/react-query";
import { useAuth } from '../context/AuthContext'
import BoxSelection from './BoxSelection'
import getTradingState from "../utils/tradingState";

const PlayerSelection = () => {
  const { poolId, teamId } = useParams();
  const { authHeaders } = useAuth();
  const navigate = useNavigate();
  const [selections, setSelections] = useState({});
  const [isSaving, setIsSaving] = useState(false);

  const {data: boxData} = useQuery({
    queryKey: ["pool_boxes", poolId],
    queryFn: () =>
      fetch(`/api/pools/${poolId}/pool_boxes`, {headers: authHeaders}).
        then(res => res.json()),
    enabled: !!poolId,
    staleTime: 5 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
  });

  const { tradingIsPendingApproval } = getTradingState(boxData?.trade_state);

  const boxes = useMemo(() => {
    if (!boxData) return [];
    return [...boxData.boxes].sort((a, b) => a.order - b.order);
  }, [boxData]);

  const isCurrentSeason = !boxData?.using_reference_season;

  useEffect(() => {
    if (!boxData) return;
    const initial = {};
    boxData.boxes.forEach(b => {
      const selected = b.players.find(p => p.selected);
      if (selected) initial[b.id] = selected.id;
    });
    setSelections(initial);
  }, [boxData]);

  const handleSubmit = async () => {
    setIsSaving(true);
    try {
      const response = await fetch(`/api/pool_teams/${teamId}/update_roster`, {
        method: "POST",
        headers: { ...authHeaders, "Accept": "application/json" },
        body: JSON.stringify({ pool_id: poolId, new_player_ids: Object.values(selections) }),
      });

      if (response.ok) {
        const { added_players, dropped_players, pending_approval } = await response.json();
        if (pending_approval) {
          alert("Your roster change has been submitted for approval.");
        } else {
          alert(`Added: ${added_players.join(", ")}\n\nDropped: ${dropped_players.join(", ")}`);
        }
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

  const saveLabel = () => {
    if (isSaving) return "Saving...";
    if (tradingIsPendingApproval) return "Request Roster Update";
    return "Save Roster";
  };

  const saveButton = (extraClass = "") => (
    <button
      className={`btn-primary ${extraClass}`}
      onClick={handleSubmit}
      disabled={isSaving || Object.keys(selections).length != boxes.length}
    >
      {saveLabel()}
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
