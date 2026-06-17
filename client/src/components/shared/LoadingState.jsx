export default function LoadingState({ error, message = "Loading..." }) {
  if (error) return <div className="loading-state--error">{error.message ?? error}</div>;
  return <div className="loading-state">{message}</div>;
}
