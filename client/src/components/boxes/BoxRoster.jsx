import { forwardRef } from "react";
import { useDroppable } from "@dnd-kit/core";
import { SortableContext, verticalListSortingStrategy } from "@dnd-kit/sortable";
import { ListEnd, ArrowUp, ArrowDown, X } from "lucide-react";
import DraggablePlayer from "./DraggablePlayer";
import { boxBadgeStyle, boxBadgeLabel } from "@/utils/boxBadgeUtils";
import { EditableField } from "@c/shared/EditableField";
import { useLeagueConstants } from "@/constants/useLeagueConstants";
import { matchesSearch } from "@/utils/searchUtils";

export default forwardRef(function BoxRoster({ box, isOver, onActions, searchTerm }, ref) {
  const { setNodeRef } = useDroppable({ id: `box:${box.name}` });
  const { positionStyles } = useLeagueConstants();
  const hasMatch = box.players.some((p) => matchesSearch(p.name, searchTerm));

  return (
    <div
      ref={(el) => {
        setNodeRef(el);
        if (ref) ref(el);
    }}
      className={`box-column ${isOver ? "box-column--over" : ""} ${hasMatch ? "box-column--match" : ""}`}
    >
      <div className="box-column__header">
        <span
          className="box-badge"
          style={boxBadgeStyle(box.position_type, box.rookie, positionStyles)}>
          {boxBadgeLabel(box.position_type, box.rookie)}
        </span>
        <span className="box-column__name">
          <EditableField
            value={box.name}
            onSave={async (newName) => onActions.rename(box.name, newName)}
            inputClassName="box-name-input"
          />
        </span>
        <span className="box-column__count">{box.players.length} Players</span>
        <div className="box-column__move">
          <button
            className="box-move-btn"
            onClick={() => onActions.addBelow(box.name)}
            aria-label="Add box below"
            title="Add box below"
          ><ListEnd size={14} /></button>
          <button
            className="box-move-btn"
            onClick={onActions.moveUp}
            disabled={!onActions.moveUp}
            aria-label="Move box up"
          ><ArrowUp size={14} /></button>
          <button
            className="box-move-btn"
            onClick={onActions.moveDown}
            disabled={!onActions.moveDown}
            aria-label="Move box down"
          ><ArrowDown size={14} /></button>
        </div>
        <button
          className="box-remove-btn"
          onClick={() => onActions.remove(box.name)}
          aria-label="Remove box"
        ><X size={16} /></button>
      </div>

      <SortableContext
        items={box.players.map((p) => p.id)}
        strategy={verticalListSortingStrategy}
      >
        <div className="box-column__players">
          {box.players.map((player) => (
            <DraggablePlayer
              key={player.id}
              player={player}
              isMatch={matchesSearch(player.name, searchTerm)}
            />
          ))}
          {box.players.length === 0 && (
            <div className="box-column__empty">Drop a player here</div>
          )}
        </div>
      </SortableContext>
    </div>
  );
});
