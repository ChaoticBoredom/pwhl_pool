// Colour utilities for report pages

// 20 vivid, high-saturation colours for team lines/swatches.
// Assigned by stable index (sorted by team ID) so the same team
// always gets the same colour regardless of rank or page.
const TEAM_COLOURS = [
  "#e63946", // vivid red
  "#2ec4b6", // vivid teal
  "#f4a261", // vivid orange
  "#4361ee", // vivid blue
  "#57cc04", // vivid green
  "#ff006e", // vivid magenta
  "#ffbe0b", // vivid yellow
  "#8338ec", // vivid purple
  "#06d6a0", // vivid mint
  "#fb5607", // vivid red-orange
  "#3a86ff", // vivid cornflower
  "#ff99c8", // vivid pink
  "#00b4d8", // vivid cyan
  "#c77dff", // vivid violet
  "#aacc00", // vivid chartreuse
  "#ff4d6d", // vivid rose
  "#0ead69", // vivid emerald
  "#ffd60a", // vivid gold
  "#4cc9f0", // vivid sky
  "#e040fb", // vivid fuchsia
];

// 20 vivid, high-saturation colours for category bars.
// Different palette from team colours to avoid visual confusion
// when both appear on screen simultaneously.
const CAT_COLOURS = [
  "#ff3a3a", // vivid red
  "#00c2ff", // vivid cyan
  "#ff9500", // vivid orange
  "#a855f7", // vivid purple
  "#00e676", // vivid green
  "#ff00aa", // vivid magenta
  "#ffe600", // vivid yellow
  "#0066ff", // vivid blue
  "#ff6b35", // vivid red-orange
  "#00ffcc", // vivid mint
  "#ff4d94", // vivid pink
  "#69db7c", // vivid lime
  "#4dabf7", // vivid sky
  "#da77f2", // vivid violet
  "#ffa94d", // vivid peach
  "#38d9a9", // vivid teal
  "#ff6b6b", // vivid coral
  "#74c0fc", // vivid cornflower
  "#ffd43b", // vivid gold
  "#63e6be", // vivid seafoam
];

const adjustLightness = (hex, delta) => {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  const clamp = (v) => Math.max(0, Math.min(255, v + delta));
  return `#${[r, g, b].map(v => clamp(v).toString(16).padStart(2, "0")).join("")}`;
};

// Teams: stable assignment by UUID sort order
export const buildColourMap = (teams) => {
  const sorted = [...teams].sort((a, b) => a.id.localeCompare(b.id));
  const map = {};
  sorted.forEach((team, i) => {
    const base = TEAM_COLOURS[i % TEAM_COLOURS.length];
    const cycle = Math.floor(i / TEAM_COLOURS.length);
    map[team.id] = cycle === 0 ? base : adjustLightness(base, +50 * cycle);
  });
  return map;
};

export const buildCatColourMap = (keys) => {
  const map = {};
  keys.forEach((k, i) => { map[k] = CAT_COLOURS[i % CAT_COLOURS.length]; });
  return map;
};
