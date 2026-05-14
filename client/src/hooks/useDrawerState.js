import { useState } from "react";

export function useDrawerState(initial = {}) {
  const [drawerState, setDrawerState] = useState({
    tab: "season_to_date",
    mode: "raw",
    clipped: false,
    ...initial,
  });

  const updateDrawer = (key, value) =>
    setDrawerState(prev => ({ ...prev, [key]: value }));

  return { drawerState, updateDrawer };
}
