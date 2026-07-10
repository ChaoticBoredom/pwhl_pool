import { useState } from "react";

export function useTradeSelection(pairs) {
  const [selected, setSelected] = useState(() => new Set(pairs.map((p) => p.poolBoxId)));

  const allSelected = selected.size === pairs.length;
  const someSelected = selected.size > 0 && !allSelected;

  const toggleAll = () => {
    setSelected(allSelected ? new Set() : new Set(pairs.map((p) => p.poolBoxId)));
  };

  const toggle = (poolBoxId) => {
    setSelected((prev) => {
      const next = new Set(prev);
      next.has(poolBoxId) ? next.delete(poolBoxId) : next.add(poolBoxId);
      return next;
    });
  };

  const selectedIds = pairs.
    filter((p) => selected.has(p.poolBoxId)).
    flatMap((p) => [p.add?.id, p.drop?.id]).
    filter(Boolean);

  const selectedMaxBackdates = pairs.
    filter((p) => selected.has(p.poolBoxId)).
    map((p) => p.maxBackdate).
    filter(Boolean)

  const effectiveMaxBackdate = selectedMaxBackdates.length
    ? selectedMaxBackdates.reduce((min, d) => (d < min ? d : min))
    : null;

  return {
    selected,
    allSelected,
    someSelected,
    toggleAll,
    toggle,
    selectedIds,
    effectiveMaxBackdate,
  };
}
