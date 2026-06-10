export function normalizePosition(position, positionGroups) {
  return Object.entries(positionGroups).find(([, variants]) =>
    variants.includes(position)
  )?.[0] ?? position;
}

export function matchesPositionFilter(position, filter, positionGroups) {
  return normalizePosition(position, positionGroups) === filter;
}
