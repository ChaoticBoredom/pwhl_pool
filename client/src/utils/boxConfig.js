import { normalizePosition } from "./positionUtils";

export function boxBadgeStyle(position, rookie, positionStyles) {
  const styles = positionStyles[position];
  if (!styles) return {};

  const border = (() => {
    switch (rookie) {
    case true: return `2.5px solid ${styles.border}`;
    case null: return `2px dashed ${styles.border}`;
    case false: return `1px solid ${styles.border}`;
    }
  })();

  return { background: styles.bg, color: styles.text, border: border };
}

export function boxBadgeLabel(position, rookie) {
  if (!position) return "?";
  return rookie === true ? `R${position}` : position;
}

export function deriveBoxBadge(players, positionGroups) {
  if (!players?.length) return { position_type: null, rookie: null };

  const positions = [...new Set(players.map((p) => normalizePosition(p.position, positionGroups)))];
  const rookieValues = [...new Set(players.map((p) => p.rookie))];

  return {
    position_type: positions.length === 1 ? positions[0] : null,
    rookie: rookieValues.length === 1 ? rookieValues[0] : null,
  };
}
