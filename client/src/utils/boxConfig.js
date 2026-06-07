export const DEFAULT_BOXES = [
  { name: "Forwards Box 1", position: "F", rookie: false, count: 1 },
  { name: "Forwards Box 2", position: "F", rookie: false, count: 1 },
  { name: "Forwards Box 3", position: "F", rookie: false, count: 1 },
  { name: "Forwards Box 4", position: "F", rookie: false, count: 1 },
  { name: "Forwards Box 5", position: "F", rookie: false, count: 1 },
  { name: "Defence Box 1", position: "D", rookie: false, count: 1 },
  { name: "Defence Box 2", position: "D", rookie: false, count: 1 },
  { name: "Defence Box 3", position: "D", rookie: false, count: 1 },
  { name: "Goalies Box 1", position: "G", rookie: null, count: 1 },
  { name: "Rookie Forwards Box 1", position: "F", rookie: true, count: 1 },
  { name: "Rookie Defence Box 1", position: "D", rookie: true, count: 1 },
];

export function boxBadgeClass(position, rookie) {
  const rookiePrefix = rookie === true ? "rookie-" : "";
  const positionKey = { F: "forward", D: "defense", G: "goalie" }[position] ?? "forward";
  return `box-badge box-badge--${rookiePrefix}${positionKey}`;
}

export function boxBadgeLabel(position, rookie) {
  return rookie === true ? `R${position}` : position;
}
