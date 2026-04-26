import { useState } from 'react';

export function EditableField({ initialValue, onSave }) {
  const [isEditing, setIsEditing] = useState(false);
  const [value, setValue] = useState(initialValue);

  const handleBlur = () => {
    setIsEditing(false);
    onSave(value);
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Enter') handleBlur();
    if (e.key === 'Escape') {
      setIsEditing(false);
      setValue(initialValue); // Revert
    }
  };

  return isEditing ? (
    <input
      autoFocus
      value={value}
      onChange={(e) => setValue(e.target.value)}
      onBlur={handleBlur}
      onKeyDown={handleKeyDown}
    />
  ) : (
    <span onClick={() => setIsEditing(true)} style={{ cursor: 'pointer' }}>
      {value || "Click to edit..."}
    </span>
  );
}
