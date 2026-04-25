import { DataRow } from './DataRow'

export function ScoringSection({ title, scorings, gridClass }) {

  return (
    <>
      <DataRow gridClass={gridClass} className="scoring-table-subheader">
        <div>{title}</div>
      </DataRow>

      {scorings?.map(scoring => (
        <DataRow key={scoring.id} gridClass={gridClass} compact>
          <div className="font-semibold text-blue-600 truncate">{scoring.field_name}</div>
          <div className="text-right font-mono text-gray-600">{scoring.value.toFixed(2)}</div>
        </DataRow>
      ))}
    </>
  );
}
