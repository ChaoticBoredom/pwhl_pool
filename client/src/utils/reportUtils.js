export const teamColour = (id) => {
  const hash = id.split("").reduce((acc, c) => acc + c.charCodeAt(0), 0);
  const hue = (hash * 137.508) % 360;
  return `hsl(${hue}, 65%, 62%)`;
};

export const fmt = (n) => (n == null ? "–" : Number(n).toFixed(2));

export const periodLabel = (from) =>
  new Date(from).toLocaleString("default", { month: "short", year: "2-digit" });

export const seasonBounds = (data) => {
  const periods = data?.teams?.[0]?.periods;
  if (!periods?.length) return { from: "", to: "" };
  return {
    from: periods[0].from.slice(0, 10),
    to:   periods.at(-1).to.slice(0, 10),
  };
};
