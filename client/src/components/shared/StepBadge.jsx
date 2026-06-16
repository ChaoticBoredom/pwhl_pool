export default function StepBadge({ step, total, label = "New Pool" }) {
  return (
    <div className="setup-step-badge">{label} — Step {step} of {total}</div>
  );
}
