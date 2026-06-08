export function normalizeString(str) {
  return str
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase();
}

export function matchesSearch(comp, search) {
  if (!search) return false;
  return normalizeString(comp).includes(normalizeString(search));
}
