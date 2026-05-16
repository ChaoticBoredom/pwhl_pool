const getTradingState = (tradingState) => ({
  tradingIsBlocked: tradingState === "blocked",
  tradingIsAllowed: tradingState === "allowed",
  tradingIsPendingApproval: tradingState === "pending_approval",
  tradingState: tradingState ?? "blocked",
});

export default getTradingState;
