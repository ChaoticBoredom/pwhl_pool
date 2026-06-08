import { useSortable } from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import Player from "@c/players/Player";
import TeamBadge from "@c/shared/TeamBadge";

export default function DraggablePlayer({ player }) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id: player.id });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.4 : 1,
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      className={`draggable-player ${isDragging ? "draggable-player--dragging" : ""}`}
      {...attributes}
      {...listeners}
    >
      <Player player={player}>
        <span className="draggable-player__position">
          {player.rookie ? `R${player.position}` : player.position}
        </span>
      </Player>
      <div className="score-display-vertical">
        <span className="score-value">{Number(player.score).toFixed(2)}</span>
        <span className="score-label">pts</span>
      </div>
    </div>
  );
}
