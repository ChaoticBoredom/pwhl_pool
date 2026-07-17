export default function StepBadge({ step, total, label = "New Pool" }) {
  return (
    <div className="label-eyebrow label-eyebrow--sm label-eyebrow--accent">{label} — Step {step} of {total}</div>
  );
}
