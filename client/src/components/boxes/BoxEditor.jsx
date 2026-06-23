import { useState, useCallback, useRef, useEffect } from "react";
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
import BoxRoster from "./BoxRoster";
import FreeAgentsPanel from "./FreeAgentsPanel";
import DraggablePlayer from "./DraggablePlayer";
import Player from "@c/players/Player";
import { matchesSearch } from "@/utils/searchUtils";
import { useLeagueConstants } from "@/constants/useLeagueConstants";
import { deriveBoxBadge } from "@/utils/boxBadgeUtils";

export default function BoxEditor({
  poolId,
  data,
  onSave,
  onCancel,
  saveLabel,
}) {
  const { authHeaders } = useAuth();

  const [boxes, setBoxes] = useState(data.boxes);
  const [freeAgents, setFreeAgents] = useState(data.free_agents);
  const [activePlayer, setActivePlayer] = useState(null);
  const [overBoxName, setOverBoxName] = useState(null);
  const [boxCounter, setBoxCounter] = useState(data.boxes.length + 1);
  const [isSaving, setIsSaving] = useState(false);
  const [search, setSearch] = useState("");
  const [error, setError] = useState(null);
  const { positionGroups } = useLeagueConstants();
  const boxRefs = useRef({});

  useEffect(() => {
    if (search.length < 3) return;

    const firstMatch = boxes.find((b) => b.players.some((p) => matchesSearch(p.name, search)));

    if (firstMatch && boxRefs.current[firstMatch.name]) {
      boxRefs.current[firstMatch.name].scrollIntoView({
        behavior: "smooth",
        block: "start",
      });
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search]);

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

  const handleRename = (oldName, newName) => {
    setBoxes((prev) => prev.map((b) =>
      b.name === oldName ?  { ...b, name: newName } : b
    ));
  };

  const handleMoveUp = (boxName) => {
    setBoxes((prev) => {
      const i = prev.findIndex((b) => b.name === boxName);
      if (i === 0) return prev;
      const next = [...prev];
      [next[i - 1], next[i]] = [next[i], next[i - 1]];
      return next;
    });
  };

  const handleMoveDown = (boxName) => {
    setBoxes((prev) => {
      const i = prev.findIndex((b) => b.name === boxName);
      if (i === prev.length - 1) return prev;
      const next = [...prev];
      [next[i], next[i + 1]] = [next[i + 1], next[i]];
      return next;
    });
  };

  const handleAddBox = (afterName) => {
    setBoxes((prev) => {
      const i = prev.findIndex((b) => b.name === afterName);
      const newBox = { name: `Pool Box ${boxCounter}`, position: i + 2, players: [] };
      return [...prev.slice(0, i + 1), newBox, ...prev.slice(i + 1)];
    });
    setBoxCounter((c) => c + 1);
  };

  const handleRemoveBox = (boxName) => {
    const box = boxes.find((b) => b.name === boxName);
    if (box?.players.length > 0) {
      setFreeAgents((fa) =>
        [...fa, ...box.players].sort((a, b) => b.score - a.score)
      );
    }
    setBoxes((prev) => prev.filter((b) => b.name !== boxName));
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
  const canSave = boxes.length >= 1 && boxes.every((b) => b.players.length >= 1);

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
            {boxes.map((box, i) => {
              const { position_type, rookie } = deriveBoxBadge(box.players, positionGroups);
              return (
                <BoxRoster
                  key={`${box.name}-${i}`}
                  ref={(el) => (boxRefs.current[box.name] = el)}
                  box={{ ...box, position_type, rookie }}
                  isOver={overBoxName === box.name}
                  searchTerm={search.length >= 3 ? search : ""}
                  onActions={{
                    rename: handleRename,
                    remove: handleRemoveBox,
                    addBelow: handleAddBox,
                    moveUp: i === 0 ? null : () => handleMoveUp(box.name),
                    moveDown: i === boxes.length - 1 ? null : () => handleMoveDown(box.name),
                  }}
                />
              );
            })}
          </div>

          <div className="box-editor__sidebar">
            <FreeAgentsPanel
              players={freeAgents}
              isDragTarget={activePlayer !== null && overBoxName === null}
              search={search}
              onSearchChange={setSearch}
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
        <button className="btn-secondary" onClick={onCancel}>
          Cancel
        </button>
        <p className="setup-confirm-meta">
          {boxes.length} boxes · {boxes.reduce((n, b) => n + b.players.length, 0)} players assigned
        </p>
        <button
          className="btn-primary"
          onClick={handleSaveClick}
          disabled={isSaving || !canSave}
          title={!canSave ? "Every box needs at least one player" : undefined}
        >
          {isSaving ? "Saving..." : saveLabel ?? "Confirm & Activate Pool →"}
        </button>
      </div>
    </div>
  );
}
