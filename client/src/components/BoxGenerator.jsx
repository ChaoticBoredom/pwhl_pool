import { useState, useCallback } from 'react'
import { useParams } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

const TEAMS = ['BOS', 'MIN', 'MTL', 'NY', 'OTT', 'TOR', 'SEA', 'VAN']
const POSITIONS = ['F', 'D', 'G']
const ROOKIE_OPTIONS = [
  { label: 'No', value: false },
  { label: 'Yes', value: true },
  { label: 'Any', value: null },
]

const DEFAULT_BOXES = [
  { name: 'Forwards Box 1', position: 'F', rookie: false, rank_range: { start: 0, end: 0 } },
  { name: 'Forwards Box 2', position: 'F', rookie: false, rank_range: { start: 1, end: 1 } },
  { name: 'Forwards Box 3', position: 'F', rookie: false, rank_range: { start: 2, end: 2 } },
  { name: 'Forwards Box 4', position: 'F', rookie: false, rank_range: { start: 3, end: 3 } },
  { name: 'Forwards Box 5', position: 'F', rookie: false, rank_range: { start: 4, end: 4 } },
  { name: 'Defence Box 1', position: 'D', rookie: false, rank_range: { start: 0, end: 0 } },
  { name: 'Defence Box 2', position: 'D', rookie: false, rank_range: { start: 1, end: 1 } },
  { name: 'Defence Box 3', position: 'D', rookie: false, rank_range: { start: 2, end: 2 } },
  { name: 'Goalies Box 1', position: 'G', rookie: null, rank_range: { start: 0, end: 0 } },
  { name: 'Rookie Forwards Box 1', position: 'F', rookie: true, rank_range: { start: 0, end: 0 } },
  { name: 'Rookie Defence Box 1', position: 'D', rookie: true, rank_range: { start: 0, end: 0 } },
]

function nextRankForPosition(boxes, position, rookie) {
  const matching = boxes.filter(b => b.position === position && b.rookie === rookie)
  if (matching.length === 0) return { start: 0, end: 0 }
  const maxEnd = Math.max(...matching.map(b => b.rank_range.end))
  return { start: maxEnd + 1, end: maxEnd + 1 }
}

function positionBadgeClass(position, rookie) {
  if (rookie === true) return 'box-badge box-badge--rookie'
  if (position === 'F') return 'box-badge box-badge--forward'
  if (position === 'D') return 'box-badge box-badge--defense'
  return 'box-badge box-badge--goalie'
}

function BoxConfigRow({ box, index, onChange, onRemove }) {
  return (
    <div className="box-config-row">
      <span className={positionBadgeClass(box.position, box.rookie)}>
        {box.rookie === true ? `R${box.position}` : box.position}
      </span>

      <input
        className="box-name-input"
        value={box.name}
        onChange={e => onChange(index, 'name', e.target.value)}
      />

      <select
        className="box-select"
        value={box.position}
        onChange={e => onChange(index, 'position', e.target.value)}
      >
        {POSITIONS.map(p => <option key={p} value={p}>{p}</option>)}
      </select>

      <select
        className="box-select"
        value={String(box.rookie)}
        onChange={e => {
          const val = e.target.value === 'true' ? true : e.target.value === 'false' ? false : null
          onChange(index, 'rookie', val)
        }}
      >
        {ROOKIE_OPTIONS.map(o => (
          <option key={String(o.value)} value={String(o.value)}>{o.label}</option>
        ))}
      </select>

      <div className="box-rank-range">
        <span className="box-rank-label">rank</span>
        <input
          className="box-rank-input"
          type="number"
          min={0}
          value={box.rank_range.start}
          onChange={e => onChange(index, 'rank_range', { ...box.rank_range, start: Math.max(0, +e.target.value) })}
        />
        <span className="box-rank-label">–</span>
        <input
          className="box-rank-input"
          type="number"
          min={box.rank_range.start}
          value={box.rank_range.end}
          onChange={e => onChange(index, 'rank_range', { ...box.rank_range, end: Math.max(box.rank_range.start, +e.target.value) })}
        />
      </div>

      <button className="box-remove-btn" onClick={() => onRemove(index)} aria-label="Remove box">×</button>
    </div>
  )
}

function ResultBox({ box }) {
  const [open, setOpen] = useState(false)
  const players = box.players || []
  const preview = players.slice(0, 3)

  return (
    <div className="result-box">
      <button className="result-box-header" onClick={() => setOpen(o => !o)}>
        <div className="result-box-title-group">
          <span className="result-box-name">{box.name}</span>
          {!open && (
            <span className="result-box-preview">
              {preview.map(p => p.name).join(', ')}{players.length > 3 ? ` +${players.length - 3}` : ''}
            </span>
          )}
        </div>
        <span className="result-box-count">{players.length} {open ? '▲' : '▼'}</span>
      </button>

      {open && (
        <div className="result-box-players">
          {players.map(player => (
            <div key={player.id} className="player-option result-player-row">
              <div className="player-display-row">
                <div className="player-identity-vertical">
                  <span className="player-name">{player.name}</span>
                  <span className="team-badge-small">{player.team_short_code}</span>
                </div>
                <div className="score-display-vertical">
                  <span className="score-value">{Number(player.score).toFixed(2)}</span>
                  <span className="score-label">pts</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

const BoxGenerator = () => {
  const { poolId } = useParams()
  const { authHeaders } = useAuth()

  const [teams, setTeams] = useState(new Set(TEAMS))
  const [maxPerTeam, setMaxPerTeam] = useState(1)
  const [boxes, setBoxes] = useState(DEFAULT_BOXES.map(b => ({ ...b, rank_range: { ...b.rank_range } })))
  const [result, setResult] = useState(null)
  const [usingRef, setUsingRef] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const toggleTeam = code => {
    setTeams(prev => {
      const next = new Set(prev)
      next.has(code) ? next.delete(code) : next.add(code)
      return next
    })
  }

  const updateBox = useCallback((index, field, value) => {
    setBoxes(prev => prev.map((b, i) => i === index ? { ...b, [field]: value } : b))
  }, [])

  const removeBox = useCallback(index => {
    setBoxes(prev => prev.filter((_, i) => i !== index))
  }, [])

  const addBox = () => {
    const position = 'F'
    const rookie = false
    const rank_range = nextRankForPosition(boxes, position, rookie)
    setBoxes(prev => [...prev, {
      name: `Forwards Box ${prev.filter(b => b.position === 'F' && !b.rookie).length + 1}`,
      position,
      rookie,
      rank_range,
    }])
  }

  const generate = async () => {
    setError(null)
    setLoading(true)
    setResult(null)

    try {
      const res = await fetch(`/api/pools/${poolId}/pool_boxes/generate`, {
        method: 'POST',
        headers: { ...authHeaders, 'Content-Type': 'application/json', 'Accept': 'application/json' },
        body: JSON.stringify({
          teams: [...teams],
          max_players_per_team: maxPerTeam || null,
          excluded_player_ids: [],
          boxes,
        }),
      })

      if (!res.ok) {
        const body = await res.json().catch(() => ({}))
        throw new Error(body.error || `Request failed: ${res.status}`)
      }

      const data = await res.json()
      setResult(data.boxes || [])
      setUsingRef(data.using_reference_season)
    } catch (e) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="selection-container">
      <header className="selection-header">
        <h1 className="pool-title">Box Generator</h1>
      </header>

      <section className="generator-section">
        <h2>Teams</h2>
        <div className="team-toggle-list">
          {TEAMS.map(code => (
            <button
              key={code}
              onClick={() => toggleTeam(code)}
              className={`team-toggle ${teams.has(code) ? 'team-toggle--active' : ''}`}
            >
              {code}
            </button>
          ))}
        </div>
      </section>

      <section className="generator-section">
        <h2>Config</h2>
        <div className="generator-config-row">
          <label className="generator-config-label">Max players per team</label>
          <input
            className="generator-config-input"
            type="number"
            min={1}
            value={maxPerTeam}
            onChange={e => setMaxPerTeam(e.target.value ? +e.target.value : '')}
          />
          <span className="helper-text">blank = global ranking</span>
        </div>
      </section>

      <section className="generator-section">
        <div className="generator-section-header">
          <h2>Boxes</h2>
          <button className="btn-primary btn-sm" onClick={addBox}>+ Add box</button>
        </div>
        <div className="box-config-list">
          {boxes.map((box, i) => (
            <BoxConfigRow key={i} box={box} index={i} onChange={updateBox} onRemove={removeBox} />
          ))}
        </div>
      </section>

      <button
        className="btn-primary btn-full"
        onClick={generate}
        disabled={loading || teams.size === 0}
      >
        {loading ? 'Generating…' : 'Generate boxes'}
      </button>

      {error && <div className="generator-error">{error}</div>}

      {result && (
        <section className="generator-section generator-results">
          <div className="generator-section-header">
            <h2>Results</h2>
            {usingRef && <span className="reference-season-badge">reference season</span>}
            <button className="btn-primary btn-sm" disabled>Save boxes</button>
          </div>
          <div className="result-box-list">
            {result.map(box => <ResultBox key={box.name} box={box} />)}
          </div>
        </section>
      )}
    </div>
  )
}

export default BoxGenerator
