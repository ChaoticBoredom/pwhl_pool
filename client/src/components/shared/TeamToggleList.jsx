export function TeamToggleList({ teamCodes, teams, selected, onToggle }) {
  return (
    <div className="team-toggle-list">
      {teamCodes.map((code) => (
        <button
          key={code}
          className={`team-toggle ${selected.has(code) ? "team-toggle--active": ""}`}
          style={selected.has(code)
            ? { background: teams[code].bg, color: teams[code].text, borderColor: teams[code].bg }
            : {}
          }
          onClick={() => onToggle(code)}
        >
          {code}
        </button>
      ))}
    </div>
  )
}
