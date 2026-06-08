import { useState, useCallback } from "react";
import {
  DndContext,
  DragOverlay,
  closestCenter,
  PointerSensor,
  useSensor,
  useSensors,
} from "@dnd-kit/core";
import { arrayMove } from "@dnd-kit/sortable";
import { useAuth } from "@/context/AuthContext";
import BoxColumn from "./BoxColumn";
import FreeAgentsPanel from "./FreeAgentsPanel";
import DraggablePlayer from "./DraggablePlayer";
import Player from "@c/players/Player";

export default function BoxEditor({
  poolId,
  initialBoxes,
  initialFreeAgents,
  onSave,
}) {
  const { authHeaders } = useAuth();

  const [boxes, setBoxes] = useState(() =>
    initialBoxes.map((box, i) => ({
      ...box,
      position: i + 1,
    }))
  );
  const [freeAgents, setFreeAgents] = useState(initialFreeAgents);
  const [activePlayer, setActivePlayer] = useState(null);
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState(null);

  const sensors = useSensors(useSensor(PointerSensor, {
    activationConstraint: { distance: 8 },
  }));

  const findSource = useCallback((playerId) => {
    const boxIndex = boxes.findIndex((b) =>
      b.players.some((p) => p.id === playerId)
    );
    if (boxIndex !== -1) return { type: "box", index: boxIndex };
    if (freeAgents.some((p) => p.id === playerId)) return { type: "free-agents" };
    return null;
  }, [boxes, freeAgents]);

  const handleDragStart = ({ active }) => {
    const source = findSource(active.id);
    if (!source) return;

    const player = source.type === "box"
      ? boxes[source.index].players.find((p) => p.id === active.id)
      : freeAgents.find((p) => p.id === active.id);

    setActivePlayer(player);
  };

  const handleDragEnd = ({ active, over }) => {
    setActivePlayer(null);
    if (!over || active.id === over.id) return;

    const source = findSource(active.id);
    if (!source) return;

    const overId = over.id;
    const isOverFreeAgents = overId === "free-agents";
    const overBoxIndex = boxes.findIndex(
      (b) => b.name === overId.replace("box:", "") ||
        b.players.some((p) => p.id === overId)
    );
    const isOverBox = overBoxIndex !== -1;

    setBoxes((prevBoxes) => {
      const next = prevBoxes.map((b) => ({ ...b, players: [...b.players] }));

      // Get the dragged player
      let player;
      if (source.type === "box") {
        player = next[source.index].players.find((p) => p.id === active.id);
        next[source.index].players = next[source.index].players.filter(
          (p) => p.id !== active.id
        );
      } else {
        player = freeAgents.find((p) => p.id === active.id);
      }

      if (isOverBox) {
        // Check if dropping on a specific player in the target box
        const targetPlayerIndex = next[overBoxIndex].players.findIndex(
          (p) => p.id === overId
        );
        if (targetPlayerIndex !== -1) {
          next[overBoxIndex].players.splice(targetPlayerIndex, 0, player);
        } else {
          next[overBoxIndex].players.push(player);
        }
      }

      return next;
    });

    setFreeAgents((prev) => {
      if (source.type === "free-agents") {
        if (isOverBox) {
          return prev.filter((p) => p.id !== active.id);
        }
        return prev;
      } else {
        // source is box
        if (isOverFreeAgents) {
          const player = boxes[source.index].players.find((p) => p.id === active.id);
          return [...prev, player].sort((a, b) => b.score - a.score);
        }
        return prev;
      }
    });
  };

  const postBoxes = useCallback(async () => {
    setError(null);
    setIsSaving(true);

    try {
      const res = await fetch(`/api/commissioner/${poolId}/pool_boxes`, {
        method: "POST",
        headers: authHeaders,
        body: JSON.stringify({
          boxes: boxes.map((box, i) => ({
            name: box.name,
            position: i + 1,
            players: box.players.map((p) => ({ id: p.id })),
          })),
        }),
      });

      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.errors?.join(", ") || "Failed to save boxes");
      }
    } catch (err) {
      setError(err.message);
      setIsSaving(false);
      throw err; // re-throw so parent knows it failed
    }

    setIsSaving(false);
  }, [boxes, poolId, authHeaders]);

  // Call onSave with postBoxes as the argument — parent decides when/whether to call it
  const handleSaveClick = () => onSave(postBoxes);

  return (
    <div className="box-editor">
      {error && <div className="generator-error">{error}</div>}

      <DndContext
        sensors={sensors}
        collisionDetection={closestCenter}
        onDragStart={handleDragStart}
        onDragEnd={handleDragEnd}
      >
        <div className="box-editor__layout">
          <div className="box-editor__boxes">
            {boxes.map((box) => (
              <BoxColumn key={box.name} box={box} />
            ))}
          </div>

          <div className="box-editor__sidebar">
            <FreeAgentsPanel players={freeAgents} />
          </div>
        </div>

        <DragOverlay>
          {activePlayer && (
            <div className="draggable-player draggable-player--overlay">
              <Player player={activePlayer} />
            </div>
          )}
        </DragOverlay>
      </DndContext>

      <div className="setup-confirm-bar">
        <p className="setup-confirm-meta">
          {boxes.length} boxes · {boxes.reduce((n, b) => n + b.players.length, 0)} players assigned
        </p>
        <button
          className="btn-primary"
          onClick={handleSaveClick}
          disabled={isSaving}
        >
          {isSaving ? "Saving…" : "Confirm & Activate Pool →"}
        </button>
      </div>
    </div>
  );
}
