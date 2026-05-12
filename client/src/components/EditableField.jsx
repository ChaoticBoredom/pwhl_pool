import { useState, useRef, useEffect } from "react";

export function EditableField({ value: initialValue, onSave, className = "", inputClassName = "" }) {
  const [editing, setEditing] = useState(false);
  const [value, setValue] = useState(initialValue);
  const [pending, setPending] = useState(false);
  const [width, setWidth] = useState("auto");
  const inputRef = useRef(null);
  const textRef = useRef(null);

  useEffect(() => {
    if (textRef.current) {
      setWidth(textRef.current.offsetWidth);
    }
  }, [value, editing]);

  useEffect(() => {
    if (editing) inputRef.current?.focus();
  }, [editing]);

  const handleSave = async () => {
    const trimmed = value.trim();
    if (!trimmed || trimmed === initialValue) {
      setValue(initialValue);
      setEditing(false);
      return;
    }
    setPending(true);
    try {
      await onSave(trimmed);
    } catch {
      setValue(initialValue);
    } finally {
      setPending(false);
      setEditing(false);
    }
  };

  const handleKeyDown = (e) => {
    if (e.key === "Enter") handleSave();
    if (e.key === "Escape") { setValue(initialValue); setEditing(false); }
  };

  if (editing) {
    return (
      <input
        ref={inputRef}
        value={value}
        onChange={e => setValue(e.target.value)}
        onBlur={handleSave}
        onKeyDown={handleKeyDown}
        disabled={pending}
        style={{ width }}
        className={inputClassName}
      />
    );
  }

  return (
    <span className="editable-field" onClick={() => setEditing(true)}>
      <span ref={textRef}>{value}</span>
      <span className="editable-field-icon">✎</span>
    </span>
  );
}
