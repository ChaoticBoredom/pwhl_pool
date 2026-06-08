import { useState, useCallback } from "react";
import {
  DndContext,
  DragOverlay,
  pointerWithin,
  PointerSensor,
  useSensor,
  useSensors,
} from "@dnd-kit/core";
import { snapCenterToCursor } from "@dnd-kit/modifiers";
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
  const [overBoxName, setOverBoxName] = useState(null);
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState(null);

  const sensors = useSensors(useSensor(PointerSensor, {
    activationConstraint: { distance: 12 },
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
    setOverBoxName(null);
    setActivePlayer(null);

    const source = findSource(active.id);
    if (!source) return;

    const player = source.type === "box"
      ? boxes[source.index].players.find((p) => p.id === active.id)
      : freeAgents.find((p) => p.id === active.id);

    if (!player) return;

    const overBoxIndex = over
      ? boxes.findIndex(
          (b) => `box:${b.name}` === over.id || b.players.some((p) => p.id === over.id)
        )
      : -1;

    const isOverBox = overBoxIndex !== -1;

    if (source.type === "box") {
      if (isOverBox && overBoxIndex !== source.index) {
        // Box → different box
        setBoxes((prev) => {
          const next = prev.map((b) => ({ ...b, players: [...b.players] }));
          next[source.index].players = next[source.index].players.filter(
            (p) => p.id !== active.id
          );
          const targetIdx = next[overBoxIndex].players.findIndex((p) => p.id === over.id);
          if (targetIdx !== -1) {
            next[overBoxIndex].players.splice(targetIdx, 0, player);
          } else {
            next[overBoxIndex].players.push(player);
          }
          return next;
        });
      } else if (!isOverBox) {
        // Box → anywhere that isn't a box = free agents
        setBoxes((prev) => prev.map((b, i) =>
          i === source.index
            ? { ...b, players: b.players.filter((p) => p.id !== active.id) }
            : b
        ));
        setFreeAgents((prev) =>
          [...prev, player].sort((a, b) => b.score - a.score)
        );
      }
    } else if (source.type === "free-agents" && isOverBox) {
      // Free agents → box
      setFreeAgents((prev) => prev.filter((p) => p.id !== active.id));
      setBoxes((prev) => {
        const next = prev.map((b) => ({ ...b, players: [...b.players] }));
        const targetIdx = next[overBoxIndex].players.findIndex((p) => p.id === over.id);
        if (targetIdx !== -1) {
          next[overBoxIndex].players.splice(targetIdx, 0, player);
        } else {
          next[overBoxIndex].players.push(player);
        }
        return next;
      });
    }
  };

  const handleDragOver = ({ over }) => {
    if (!over) { setOverBoxName(null); return; }
    const overBoxIndex = boxes.findIndex(
      (b) => `box:${b.name}` === over.id || b.players.some((p) => p.id === over.id)
    );
    setOverBoxName(overBoxIndex !== -1 ? boxes[overBoxIndex].name : null);
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
        collisionDetection={pointerWithin}
        onDragOver={handleDragOver}
        onDragStart={handleDragStart}
        onDragEnd={handleDragEnd}
      >
        <div className="box-editor__layout">
          <div className="box-editor__boxes">
            {boxes.map((box) => (
              <BoxColumn key={box.name} box={box} isOver={overBoxName == box.name} />
            ))}
          </div>

          <div className="box-editor__sidebar">
            <FreeAgentsPanel
              players={freeAgents}
              isDragTarget={activePlayer !== null && overBoxName === null}
            />
          </div>
        </div>

        <DragOverlay dropAnimation={null} modifiers={[snapCenterToCursor]}>
          {activePlayer && (
            <div className="draggable-player draggable-player--overlay draggable-player--compact">
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
