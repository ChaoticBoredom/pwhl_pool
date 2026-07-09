export function ToggleGroup({
  mode,
  className = "toggle-btn",
  wrapperClassName,
  options,
  value,
  onChange,
}) {
  if (import.meta.env.DEV) {
    if (mode === "multi" && !(value instanceof Set)) {
      console.warn("ToggleGroup: mode=\"multi\" expects a Set for `value`, received:", value);
    }
    if (mode === "exclusive" && value instanceof Set) {
      console.warn("ToggleGroup: mode=\"exclusive\" expects a raw value for `value`, received a Set.");
    }
  }

  const handleClick = (optionValue) => {
    if (mode === "multi") {
      const next = new Set(value);
      next.has(optionValue) ? next.delete(optionValue) : next.add(optionValue);
      onChange(next);
    } else {
      onChange(optionValue);
    }
  };

  const isActive = (optionValue) =>
    mode === "multi" ? value.has(optionValue) : value === optionValue;

  const resolvedWrapperClass = wrapperClassName ?? `toggle-group toggle-group--${mode}`;

  return (
    <div className={resolvedWrapperClass}>
      {options.map(({ label, value: optionValue, style }) => (
        <button
          key={optionValue}
          className={`${className}${isActive(optionValue) ? ` ${className}--active` : ""}`}
          style={style}
          onClick={() => handleClick(optionValue)}
        >
          {label}
        </button>
      ))}
    </div>
  );
}
