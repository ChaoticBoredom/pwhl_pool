export function formatDate(isoString, options = {}) {
  return new Date(isoString).toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
    ...options,
  });
}

export function formatDateTime(isoString, options = {}) {
  return new Date(isoString).toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
    ...options,
  });
}

export function formatDateRange(startIso, endIso, options = {}) {
  return `${formatDateTime(startIso, options)} \u2013 ${formatDateTime(endIso, options)}`;
}

export function formatTime(isoString) {
  return new Date(isoString).toLocaleTimeString();
}
