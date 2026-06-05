export function formatDate(isoString, options = {}) {
  return new Date(isoString).toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    ...options,
  });
}

export function formatDateTime(isoString, options = {}) {
  return new Date(isoString).toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
    ...options,
  });
}

export function formatTime(isoString) {
  return new Date(isoString).toLocaleTimeString();
}
