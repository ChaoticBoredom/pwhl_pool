import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";
import { usePool } from "@/context/PoolContext";
import { Plus } from "lucide-react";
// import TradeWindowRow from "./TradeWindowRow";

export default function TradeWindows() {
  const { pool } = usePool();
  const { authHeaders } = useAuth();
  const queryClient = useQueryClient();

  const windowsQuery = useQuery({
    queryKey: ["trade-windows", pool.id],
    queryFn: async () => {
      const res = await  fetch(`/api/commissioner/${pool.id}/trade_windows`, { headers: authHeaders });
      if (!res.ok) throw new Error("Failed to load trade windows");
      return res.json();
    },
  });

  const invalidateWindows = () => queryClient.invalidateQueries({ queryKey: ["trade-windows", pool.id] });

  const createMutation = useMutation({
    mutationFn: async ({ window_start, window_end }) => {
      const res = await fetch(`/api/commissioner/${pool.id}/trade_windows`, {
        method: "POST",
        headers: authHeaders,
        body: JSON.stringify({ open_window_start: window_start, open_window_end: window_end }),
      });

      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.error || err.errors?.join(", ") || "Failed to create trade window");
      }

      return res.json();
    },
    onSuccess: invalidateWindows,
  });

  const updateMutation = useMutation({
    mutationFn: async ({ id, window_start, window_end }) => {
      const res = await fetch(`/api/commissioner/${pool.id}/trade_windows/${id}`, {
        method: "PATCH",
        headers: authHeaders,
        body: JSON.stringify({ open_window_start: window_start, open_window_end: window_end }),
      });

      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.error || err.errors.join(", ") || "Failed to update trade window");
      }

      return res.json();
    },
    onSuccess: invalidateWindows,
  });

  const deleteMutation = useMutation({
    mutationFn: async (id) => {
      const res = await fetch(`/api/commissioner/${pool.id}/trade_windows/${id}`, {
        method: "DELETE",
        headers: authHeaders,
      });

      if (!res.ok) throw new Error("Failed to delete trade window");
    },
    onSuccess: invalidateWindows,
  });

  return (
    <div className="stack">
      <h2 className="page-title">Trade Windows</h2>
      <p className="helper-text">
        Trades are also blocked automatically once the first game of the day begins,
        regardless of window settings.
      </p>

      {windowsQuery.isLoading && <div className="loading-state">Loading trade windows...</div>}
      {windowsQuery.isError && <div className="loading-state--error">Failed to load trade windows.</div>}

      {windowsQuery.data && (
        <div className="stack">
          {/*{windowsQuery.data.map((window) => (
            <TradeWindowRow
              key={window.id}
              window={window}
              onSave={(values) => updateMutation.mutateAsync({ id: window.id, ...values })}
              onDelete={() => deleteMutation.mutateAsync(window.id)}
            />
          ))}

          <TradeWindowRow
            isNew
            onSave={(values) => createMutation.mutateAsync(values)}
          />*/}
        </div>
      )}
    </div>
  );
}
