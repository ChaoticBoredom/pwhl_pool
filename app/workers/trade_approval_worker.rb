class TradeApprovalWorker
  include Sidekiq::Worker

  def perform(request_group_id)
    requests = Trade::Request.
      where(request_group_id: request_group_id).
      trade_status_approved

    return if requests.none?

    Trade::ApplicationService.from_approved_requests(requests).call
  end
end
