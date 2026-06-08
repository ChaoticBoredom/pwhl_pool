import { useDroppable } from "@dnd-kit/core";
import { SortableContext, verticalListSortingStrategy } from "@dnd-kit/sortable";
import DraggablePlayer from "./DraggablePlayer";
import { boxBadgeClass, boxBadgeLabel } from "@/utils/boxConfig";

export default function BoxColumn({ box }) {
  const { setNodeRef, isOver } = useDroppable({ id: `box:${box.name}` });

  return (
    <div className={`box-column ${isOver ? "box-column--over" : ""}`}>
      <div className="box-column__header">
        <span className={`box-badge ${boxBadgeClass(box.position, box.rookie)}`}>
          {boxBadgeLabel(box.position, box.rookie)}
        </span>
        <span className="box-column__name">{box.name}</span>
        <span className="box-column__count">{box.players.length}</span>
      </div>

      <SortableContext
        items={box.players.map((p) => p.id)}
        strategy={verticalListSortingStrategy}
      >
        <div ref={setNodeRef} className="box-column__players">
          {box.players.map((player) => (
            <DraggablePlayer key={player.id} player={player} />
          ))}
          {box.players.length === 0 && (
            <div className="box-column__empty">Drop a player here</div>
          )}
        </div>
      </SortableContext>
    </div>
  );
}
