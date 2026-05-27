const DISTINCT_COLOURS = [
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
  "#ff99c8", // vivid pink (saturated, not pastel)
  "#00b4d8", // vivid cyan
  "#c77dff", // vivid violet
  "#aacc00", // vivid chartreuse
  "#ff4d6d", // vivid rose
  "#0ead69", // vivid emerald
  "#ffd60a", // vivid gold
  "#4cc9f0", // vivid sky
  "#e040fb", // vivid fuchsia
];

const adjustLightness = (hex, delta) => {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  const clamp = (v) => Math.max(0, Math.min(255, v + delta));
  return `#${[r, g, b].map(v => clamp(v).toString(16).padStart(2, "0")).join("")}`;
};

export const buildColourMap = (teams) => {
  const sorted = [...teams].sort((a, b) => a.id.localeCompare(b.id));
  const map = {};
  sorted.forEach((team, i) => {
    const base = DISTINCT_COLOURS[i % DISTINCT_COLOURS.length];
    const cycle = Math.floor(i / DISTINCT_COLOURS.length);
    // Overflow goes lighter (pastel direction) rather than darker
    map[team.id] = cycle === 0 ? base : adjustLightness(base, +50 * cycle);
  });
  return map;
};

export const fmt = (n) => (n == null ? "–" : Number(n).toFixed(2));

export const periodLabel = (from) =>
  new Date(from).toLocaleString("default", { month: "short", year: "2-digit" });

export const seasonBounds = (data) => {
  const periods = data?.teams?.[0]?.periods;
  if (!periods?.length) return { from: "", to: "" };
  return {
    from: periods[0].from.slice(0, 10),
    to: periods.at(-1).to.slice(0, 10),
  };
};

export const isValidDate = (str) => {
  if (!str || str.length < 10) return false;
  const d = new Date(str);
  return !isNaN(d) && d.getFullYear() >= 2000;
};
