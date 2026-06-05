import { useMemo, useState, useRef } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";
import useNotices from "@/hooks/useNotices";
import BoxSelection from "@c/boxes/BoxSelection";
import SelectionDetailPanel from "@c/boxes/SelectionDetailPanel";
import PendingTradesSection from "@c/trades/PendingTradesSection";
import getTradingState from "@/utils/tradingState";

const DESKTOP_BREAKPOINT = 1024;

const useIsDesktop = () => {
  const [isDesktop, setIsDesktop] = useState(
    () => window.innerWidth >= DESKTOP_BREAKPOINT,
  );
  return isDesktop;
};

const PlayerSelection = () => {
  const { poolId, teamId } = useParams();
  const { authHeaders } = useAuth();
  const navigate = useNavigate();
  const { add: addNotice } = useNotices();
  const queryClient = useQueryClient();
  const isDesktop = useIsDesktop();
  const pendingsSectionRef = useRef(null);

  const [detailPanel, setDetailPanel] = useState(null);

  const { data: boxData } = useQuery({
    queryKey: ["pool_boxes", poolId, teamId],
    queryFn: () =>
      fetch(`/api/pools/${poolId}/pool_boxes?pool_team_id=${teamId}`, { headers: authHeaders })
        .then(res => res.json()),
    enabled: !!poolId && !!teamId,
    staleTime: 5 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
  });

  const { tradingIsPendingApproval } = getTradingState(boxData?.trading_state);
  const hasPendingTrades = boxData?.pending_trades ?? false;

  const { data: tradeRequests = [] } = useQuery({
    queryKey: ["trade_requests", teamId],
    queryFn: () =>
      fetch(`/api/pool_teams/${teamId}/trade_requests?status=pending`, { headers: authHeaders })
        .then(res => res.json()),
    enabled: !!teamId && tradingIsPendingApproval,
    staleTime: 30 * 1000,
    gcTime: 5 * 60 * 1000,
  });

  // Group pending requests by player id for badge display
  const pendingByPlayer = useMemo(() => {
    return tradeRequests.reduce((acc, r) => {
      const pid = r.league_player.id;
      if (!acc[pid]) acc[pid] = [];
      acc[pid].push(r);
      return acc;
    }, {});
  }, [tradeRequests]);

  // Group pending requests by box id for the panel
  const pendingByBox = useMemo(() => {
    return tradeRequests.reduce((acc, r) => {
      if (!acc[r.pool_box_id]) acc[r.pool_box_id] = [];
      acc[r.pool_box_id].push(r);
      return acc;
    }, {});
  }, [tradeRequests]);

  const boxes = useMemo(() => {
    if (!boxData) return [];
    return [...boxData.boxes].sort((a, b) => a.order - b.order);
  }, [boxData]);

  const isCurrentSeason = !boxData?.using_reference_season;

  const initialSelections = useMemo(() => {
    if (!boxData) return {};
    const initial = {};
    boxData.boxes.forEach(b => {
      const selected = b.players.find(p => p.selected);
      if (selected) initial[b.id] = selected.id;
    });
    return initial;
  }, [boxData]);

  const [rawSelections, setSelections] = useState({});
  const selections = { ...initialSelections, ...rawSelections };

  const invalidateAfterSubmit = () => {
    queryClient.invalidateQueries({ queryKey: ["pool_boxes", poolId, teamId] });
    queryClient.invalidateQueries({ queryKey: ["trade_requests", teamId] });
  };

  const { mutate: submitRoster, isPending: isSubmitting } = useMutation({
    mutationFn: ({ confirmReplace } = {}) =>
      fetch(`/api/pool_teams/${teamId}/trade_requests`, {
        method: "POST",
        headers: { ...authHeaders, "Accept": "application/json", "Content-Type": "application/json" },
        body: JSON.stringify({
          pool_id: poolId,
          new_player_ids: Object.values(selections),
          ...(confirmReplace ? { confirm_replace: true } : {}),
        }),
      }).then(async res => {
        const body = await res.json().catch(() => ({}));
        return { status: res.status, body };
      }),

    onSuccess: ({ status, body }) => {
      if (status === 200) {
        addNotice({ severity: "success", message: "Roster updated successfully." });
        invalidateAfterSubmit();
        navigate(`/pools/${poolId}/teams/${teamId}`);
        return;
      }

      if (status === 201) {
        addNotice({
          severity: "info",
          message: "Your roster change has been submitted for approval.",
        });
        invalidateAfterSubmit();
        navigate(`/pools/${poolId}/teams/${teamId}`);
        return;
      }

      if (status === 409) {
        const conflicts = body.conflicts ?? [];
        const names = conflicts
          .filter(c => c.action === "drop")
          .map(c => c.league_player.name)
          .join(", ");

        addNotice({
          severity: "action",
          message: `Conflicting pending requests exist for: ${names}. Replace them and continue?`,
          dismissable: false,
          actions: [
            {
              label: "Replace & Submit",
              onClick: () => submitRoster({ confirmReplace: true }),
            },
            {
              label: "Cancel",
              variant: "secondary",
              onClick: () => {},
              dismissOnClick: true,
            },
          ],
        });
        return;
      }

      if (status === 403) {
        addNotice({
          severity: "error",
          message: body.error ?? "Trades are currently locked for this pool.",
        });
        if (!body.reason || body.reason !== "trades_closed") {
          navigate(`/pools/${poolId}`);
        }
        return;
      }

      addNotice({
        severity: "error",
        message: body.errors?.join(", ") ?? "Failed to update roster. Please try again.",
      });
    },

    onError: () => {
      addNotice({
        severity: "error",
        message: "Something went wrong. Please check your connection and try again.",
      });
    },
  });

  const { mutate: cancelRequest, isPending: isCancelling } = useMutation({
    mutationFn: (poolBoxId) =>
      fetch(`/api/pool_teams/${teamId}/trade_requests/cancel`, {
        method: "POST",
        headers: authHeaders,
        body: JSON.stringify({ pool_box_id: poolBoxId }),
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["trade_requests", teamId], refetchType: "all" });
      queryClient.invalidateQueries({ queryKey: ["pool_boxes", poolId, teamId], refetchType: "all" });
      setDetailPanel(prev => prev?.type === "trades" ? { ...prev, requests: [] } : prev);
    },
    onError: () => {
      addNotice({ severity: "error", message: "Failed to cancel request. Please try again." });
    },
  });

  const handleExpandDetails = (type, payload) => {
    if (type === "comparison") {
      setDetailPanel({ type: "comparison", boxId: payload.boxId, boxName: payload.boxName, players: payload.players });
    } else if (type === "trades") {
      setDetailPanel({ type: "trades" });
    }
  };

  const saveLabel = () => {
    if (isSubmitting) return "Saving...";
    if (tradingIsPendingApproval) return "Request Roster Update";
    return "Save Roster";
  };

  const saveButton = (extraClass = "") => (
    <button
      className={`btn-primary ${extraClass}`}
      onClick={() => submitRoster({})}
      disabled={isSubmitting || Object.keys(selections).length !== boxes.length}
    >
      {saveLabel()}
    </button>
  );

  return (
    <div className="selection-container">
      <header className="selection-header">
        <h1>Select Players</h1>
        {saveButton("btn-top")}
      </header>

      <div className={`selection-layout ${isDesktop ? "selection-layout--desktop" : ""}`}>
        <div className="selection-grid">
          {boxes.map(box => (
            <BoxSelection
              key={box.id}
              box={box}
              isCurrentSeason={isCurrentSeason}
              selectedPlayerId={selections[box.id]}
              onSelect={(playerId) => setSelections({ ...rawSelections, [box.id]: playerId })}
              pendingByPlayer={pendingByPlayer}
              onExpandDetails={handleExpandDetails}
              isDesktop={isDesktop}
            />
          ))}
        </div>

        {isDesktop && (
          <aside className="selection-panel-aside">
            <SelectionDetailPanel
              panel={detailPanel}
              boxes={boxes}
              tradeRequests={tradeRequests}
              selectedPlayerId={detailPanel?.boxId ? selections[detailPanel.boxId] : null}
              onCancelRequest={cancelRequest}
              isCancelling={isCancelling}
            />
          </aside>
        )}
      </div>

      {/* Mobile: pending requests section */}
      {!isDesktop && hasPendingTrades && tradeRequests.length > 0 && (
        <PendingTradesSection
          tradeRequests={tradeRequests}
          boxes={boxes}
          onCancel={cancelRequest}
          isCancelling={isCancelling}
        />
      )}

      <footer className="selection-footer">
        {saveButton("btn-full")}
        <span className="helper-text">
          Make sure you have selected a player from every box before saving.
        </span>
      </footer>
    </div>
  );
};

export default PlayerSelection;
