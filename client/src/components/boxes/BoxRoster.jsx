import { forwardRef } from "react";
import { useDroppable } from "@dnd-kit/core";
import { SortableContext, verticalListSortingStrategy } from "@dnd-kit/sortable";
import { ListEnd, ArrowUp, ArrowDown, X } from "lucide-react";
import DraggablePlayer from "./DraggablePlayer";
import { positionLegendStyle, positionLegendLabel } from "@/utils/positionLegendUtils";
import { EditableField } from "@c/shared/EditableField";
import IconButton from "@c/shared/IconButton";
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
      className={`box-column panel ${isOver ? "box-column--over" : ""} ${hasMatch ? "box-column--match" : ""}`}
    >
      <div className="panel__header panel__header--gap">
        <span
          className="position-legend"
          style={positionLegendStyle(box.position_type, box.rookie, positionStyles)}>
          {positionLegendLabel(box.position_type, box.rookie)}
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
          <IconButton icon={ListEnd} label="Add box below" onClick={onActions.addBelow} />
          <IconButton icon={ArrowUp} label="Move box up" onClick={onActions.moveUp} disabled={!onActions.moveUp} />
          <IconButton icon={ArrowDown} label="Move box down" onClick={onActions.moveDown} disabled={!onActions.moveDown} />
        </div>
        <IconButton icon={X} label="Remove box" onClick={onActions.remove} size={16} />
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
