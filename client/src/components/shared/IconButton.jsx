// eslint-disable-next-line no-unused-vars
export default function IconButton({ icon: Icon, label, onClick, disabled, size = 14, className = "" }) {
  return (
    <button
      className={`icon-btn${className ? ` ${className}` : ""}`}
      onClick={onClick}
      disabled={disabled}
      title={label}
      aria-label={label}
    >
      <Icon size={size} />
    </button>
  );
}
