import { useState } from "react";
import { useLeagueConstants } from "@/constants/useLeagueConstants";
import { TeamToggleList } from "@c/shared/TeamToggleList";
import { ToggleGroup } from "@c/shared/ToggleGroup";
import { boxBadgeStyle, boxBadgeLabel } from "@/utils/boxBadgeUtils";

export default function StyleGuide() {
  const { teamCodes, teams, positionStyles } = useLeagueConstants();
  const [selected, setSelected] = useState(new Set(teamCodes));
  const [exclusiveDemo, setExclusiveDemo] = useState("active");
  const [multiDemo, setMultiDemo] = useState(new Set(["F"]));

  return (
    <div className="app-wrapper" style={{ display: "flex", flexDirection: "column", gap: "2rem" }}>
      <h1 className="page-title">Style Guide</h1>

      <section>
        <h2>Trade Status Badges</h2>
        <div style={{ display: "flex", gap: "0.5rem", flexWrap: "wrap" }}>
          <span className="trade-status-badge trade-status-badge--pending">Pending</span>
          <span className="trade-status-badge trade-status-badge--approved">Approved</span>
          <span className="trade-status-badge trade-status-badge--auto_approved">Auto-Approved</span>
          <span className="trade-status-badge trade-status-badge--rejected">Rejected</span>
          <span className="trade-status-badge trade-status-badge--auto_rejected">Auto-Rejected</span>
          <span className="trade-status-badge trade-status-badge--cancelled">Cancelled</span>
          <span className="trade-status-badge trade-status-badge--auto_cancelled">Auto-Cancelled</span>
        </div>
      </section>

      <section>
        <h2>Action Badges</h2>
        <div style={{ display: "flex", gap: "0.5rem", flexWrap: "wrap" }}>
          <span className="action-badge action-badge--add">Add</span>
          <span className="action-badge action-badge--drop">Drop</span>
        </div>
      </section>

      <section>
        <h2>Position Badges (false / true / mixed)</h2>
        <div style={{ display: "flex", gap: "0.5rem", flexWrap: "wrap" }}>
          {Object.keys(positionStyles).map((pos) => (
            <span key={`${pos}-false`} className="box-badge" style={boxBadgeStyle(pos, false, positionStyles)}>
              {boxBadgeLabel(pos, false)}
            </span>
          ))}
        </div>
        <div style={{ display: "flex", gap: "0.5rem", flexWrap: "wrap", marginTop: "0.5rem" }}>
          {Object.keys(positionStyles).map((pos) => (
            <span key={`${pos}-true`} className="box-badge" style={boxBadgeStyle(pos, true, positionStyles)}>
              {boxBadgeLabel(pos, true)}
            </span>
          ))}
        </div>
        <div style={{ display: "flex", gap: "0.5rem", flexWrap: "wrap", marginTop: "0.5rem" }}>
          {Object.keys(positionStyles).map((pos) => (
            <span key={`${pos}-mixed`} className="box-badge" style={boxBadgeStyle(pos, null, positionStyles)}>
              {boxBadgeLabel(pos, null)}
            </span>
          ))}
        </div>
      </section>

      <section>
        <h2>Notice Severities</h2>
        <div className="notice-bar" style={{ position: "static" }}>
          <div className="notice-bar__item notice-bar__item--success">
            <span className="notice-bar__icon">✓</span>
            <span className="notice-bar__message">Success notice</span>
          </div>
          <div className="notice-bar__item notice-bar__item--info">
            <span className="notice-bar__icon">i</span>
            <span className="notice-bar__message">Info notice</span>
          </div>
          <div className="notice-bar__item notice-bar__item--warning">
            <span className="notice-bar__icon">!</span>
            <span className="notice-bar__message">Warning notice</span>
          </div>
        </div>
      </section>

      <section>
        <h2>Buttons</h2>
        <div style={{ display: "flex", gap: "0.5rem", flexWrap: "wrap" }}>
          <button className="btn-primary">Primary</button>
          <button className="btn-primary" disabled>Primary (disabled)</button>
          <button className="btn-secondary">Secondary</button>
          <button className="btn-secondary" disabled>Secondary (disabled)</button>
          <button className="btn-link">Link button</button>
        </div>
      </section>

      <section>
        <h2>Form Elements</h2>
        <div style={{ display: "flex", flexDirection: "column", gap: "1rem", maxWidth: "400px" }}>
          <div className="form-field">
            <label className="label-eyebrow label-eyebrow--md">Text input</label>
            <input className="form-input" placeholder="Placeholder text" />
          </div>
          <div className="form-field">
            <label className="label-eyebrow label-eyebrow--md">Textarea</label>
            <textarea className="form-input" rows={3} placeholder="Placeholder text" />
          </div>
          <div className="form-field">
            <label className="label-eyebrow label-eyebrow--md">Select</label>
            <select className="form-select">
              <option>Option A</option>
              <option>Option B</option>
            </select>
          </div>
          <label className="form-toggle-row">
            <input type="checkbox" />
            <span className="form-toggle-label">Plain checkbox</span>
          </label>
          <label className="form-toggle-row">
            <input type="checkbox" className="trade-checkbox" defaultChecked />
            <span className="form-toggle-label">Styled (.trade-checkbox)</span>
          </label>
          <div className="radio-option">
            <input type="radio" name="sg-radio" defaultChecked />
            <span>Radio option A</span>
          </div>
          <div className="radio-option">
            <input type="radio" name="sg-radio" />
            <span>Radio option B</span>
          </div>
        </div>
      </section>

      <section>
        <h2>Team Toggle Pills (all teams — click to toggle)</h2>
        <TeamToggleList
          teamCodes={teamCodes}
          teams={teams}
          selected={selected}
          onChange={setSelected}
        />
      </section>

      <section>
        <h2>Toggle Group — Exclusive</h2>
        <ToggleGroup
          mode="exclusive"
          options={[{ value: "active", label: "Active" }, { value: "inactive", label: "Inactive" }]}
          value={exclusiveDemo}
          onChange={setExclusiveDemo}
        />
      </section>

      <section>
        <h2>Toggle Group — Multi</h2>
        <ToggleGroup
          mode="multi"
          options={[{ value: "F", label: "F" }, { value: "D", label: "D" }, { value: "G", label: "G" }]}
          value={multiDemo}
          onChange={setMultiDemo}
        />
      </section>
    </div>
  );
}
