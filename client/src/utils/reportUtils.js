export const fmt = (n) => (n == null ? "–" : Number(n).toFixed(2));

export const periodLabel = (from, period) => {
  const d = new Date(from);
  if (period === "day" || period === "week") {
    return d.toLocaleString("default", { month: "short", day: "numeric" });
  }
  return d.toLocaleString("default", { month: "short", year: "2-digit" });
};

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
