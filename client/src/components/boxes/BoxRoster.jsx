import { forwardRef } from "react";
import { useDroppable } from "@dnd-kit/core";
import { SortableContext, verticalListSortingStrategy } from "@dnd-kit/sortable";
import { ListEnd, ArrowUp, ArrowDown, X } from "lucide-react";
import DraggablePlayer from "./DraggablePlayer";
import { boxBadgeStyle, boxBadgeLabel } from "@/utils/boxBadgeUtils";
import { EditableField } from "@c/shared/EditableField";
import { useLeagueConstants } from "@/constants/useLeagueConstants";
import { matchesSearch } from "@/utils/searchUtils";

// eslint-disable-next-line no-unused-vars
function BoxActionButton({ icon: Icon, label, onClick, disabled, className = "box-move-btn", size = 14 }) {
  return (
    <button
      className={className}
      onClick={onClick}
      disabled={disabled}
      title={label}
      aria-label={label}
    >
      <Icon size={size} />
    </button>
  );
}

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
      className={`box-column panel ${isOver ? "box-column--over" : ""} ${hasMatch ? "box-column--match" : ""}`}
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
            onSave={onActions.rename}
            inputClassName="box-name-input"
          />
        </span>
        <span className="box-column__count">{box.players.length} Players</span>
        <div className="box-column__move">
          <BoxActionButton icon={ListEnd} label="Add box below" onClick={onActions.addBelow} />
          <BoxActionButton icon={ArrowUp} label="Move box up" onClick={onActions.moveUp} disabled={!onActions.moveUp} />
          <BoxActionButton icon={ArrowDown} label="Move box down" onClick={onActions.moveDown} disabled={!onActions.moveDown} />
        </div>
        <BoxActionButton icon={X} label="Remove box" onClick={onActions.remove} size={16} />
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
