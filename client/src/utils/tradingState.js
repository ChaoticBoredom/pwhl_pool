const getTradingState = (tradingState) => {
  const state = tradingState ?? "blocked";
  return {
    tradingIsBlocked: state === "blocked",
    tradingIsAllowed: state === "allowed",
    tradingIsPendingApproval: state === "pending_approval",
    tradingState: state,
  }
};

export default getTradingState;
