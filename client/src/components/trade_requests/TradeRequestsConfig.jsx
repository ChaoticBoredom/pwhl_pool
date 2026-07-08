import { useState } from "react";
import { useParams } from "react-router-dom";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";
import useNotices from "@/hooks/useNotices";
import LoadingState from "@c/shared/LoadingState";
import TradeGroup from "./TradeGroup";
import { groupTradeRequests } from "@/utils/groupTradeRequests";

const STATUS_GROUPS = {
  pending: ["pending"],
  approved: ["approved", "auto_approved"],
  rejected: ["rejected", "auto_rejected"],
  cancelled: ["cancelled", "auto_cancelled"],
};

export default function TradeRequestsConfig() {
  const { poolId } = useParams();
  const { authHeaders } = useAuth();
  const { add } = useNotices();
  const queryClient = useQueryClient();

  const [activeStatuses, setActiveStatuses] = useState(new Set(["pending"]));

  const toggleStatus = (key) => {
    setActiveStatuses((prev) => {
      const next = new Set(prev);
      next.has(key) ? next.delete(key) : next.add(key);
      return next;
    });
  };

  const { data: requests, isLoading, error } = useQuery({
    queryKey: ["commissioner-trade-requests", poolId],
    queryFn: async () => {
      const res = await fetch(`/api/commissioner/${poolId}/trade_requests`, {
        headers: authHeaders,
      });
      if (!res.ok) throw new Error("Failed to load trade requests");
      return res.json();
    },
  });

  const decideMutation = useMutation({
    mutationFn: async ({ status, ids, rejected_reason, backdated_to }) => {
      const res = await fetch(`/api/commissioner/${poolId}/trade_requests`, {
        method: "PATCH",
        headers: authHeaders,
        body: JSON.stringify({ status, ids, rejected_reason, backdated_to }),
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        throw new Error(body.error || "Failed to update trade requests");
      }
      return res.json();
    },
    onSuccess: (_data, { status }) => {
      add({ severity: "success", message: `Trade request ${status === "approved" ? "approved" : "rejected"}.` });
      queryClient.removeQueries({ queryKey: ["commissioner-trade-requests", poolId] });
    },
    onError: (err) => {
      add({ severity: "error", message: err.message });
    },
  });

  const handleDecide = (status, ids, extra = {}) => {
    decideMutation.mutate({ status, ids, ...extra });
  };

  if (isLoading || error) {
    return <LoadingState error={error} message="Loading trade requests..." />;
  }

  const visibleStatuses = [...activeStatuses].flatMap((key) => STATUS_GROUPS[key]);
  const filteredRequests = requests.filter((r) => visibleStatuses.includes(r.status));
  const groups = groupTradeRequests(filteredRequests);

  return (
    <div className="app-wrapper">
      <h1 className="setup-page-title">Trade Requests</h1>

      <div className="free-agents-panel__filter-group">
        {Object.keys(STATUS_GROUPS).map((key) => (
          <button
            key={key}
            className={`filter-toggle ${activeStatuses.has(key) ? "filter-toggle--active" : ""}`}
            onClick={() => toggleStatus(key)}
          >
            {key.charAt(0).toUpperCase() + key.slice(1)}
          </button>
        ))}
      </div>

      {groups.length === 0 ? (
        <LoadingState
          message={requests.length === 0
            ? "No trade requests for this pool yet."
            : "All requests filtered out — try enabling another status above."}
        />
      ) : (
        groups.map((group) => (
          <TradeGroup
            key={group.groupId}
            teamName={group.teamName}
            ownerName={group.ownerName}
            requestedAt={group.requestedAt}
            status={group.status}
            pairs={group.pairs}
            onDecide={handleDecide}
            isDeciding={decideMutation.isPending}
          />
        ))
      )}
    </div>
  );
}
