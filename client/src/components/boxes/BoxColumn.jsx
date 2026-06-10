import { forwardRef } from "react";
import { useDroppable } from "@dnd-kit/core";
import { SortableContext, verticalListSortingStrategy } from "@dnd-kit/sortable";
import DraggablePlayer from "./DraggablePlayer";
import { boxBadgeStyle, boxBadgeLabel } from "@/utils/boxConfig";
import { EditableField } from "@c/shared/EditableField";
import { useLeagueConstants } from "@/constants/useLeagueConstants";
import { matchesSearch } from "@/utils/searchUtils";

const BoxColumn = forwardRef(({ box, isOver, onRename, onRemove, searchTerm }, ref) => {
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
            onSave={async (newName) => onRename(box.name, newName)}
            inputClassName="box-name-input"
          />
        </span>
        <span className="box-column__count">{box.players.length} Players</span>
        <button
          className="box-remove-btn"
          onClick={() => onRemove(box.name)}
          aria-label="Remove box"
        >×</button>
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
})

export default BoxColumn;
