export const CAT_COLOURS = [
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

export const buildCatColourMap = (keys) => {
  const map = {};
  keys.forEach((k, i) => { map[k] = CAT_COLOURS[i % CAT_COLOURS.length]; });
  return map;
};
