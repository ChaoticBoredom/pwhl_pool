const POSITION_GROUPS = {
  F: ["F", "LW", "RW", "C"],
  D: ["D", "LD", "RD"],
  G: ["G"],
};

export function normalizePosition(position) {
  return Object.entries(POSITION_GROUPS).find(([, variants]) =>
    variants.includes(position)
  )?.[0] ?? position;
}

export function matchesPositionFilter(position, filter) {
  return normalizePosition(position) === filter;
}
