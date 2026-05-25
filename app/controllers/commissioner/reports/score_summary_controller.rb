class Commissioner::Reports::ScoreSummaryController < Commissioner::BaseController
  def show
    pool_start, pool_end = @pool.start_end_range.minmax
    @from = params[:from] ? Time.zone.parse(params[:from]).beginning_of_day : pool_start
    @to = params[:to] ? Time.zone.parse(params[:to]).end_of_day : [pool_end, 1.day.ago.end_of_day].min
    @range = @from..@to
    @breakdowns = Array(params[:breakdowns] || "by_team")

    @report = Reports::ScoreSummaryService.new(
      @pool,
      @range,
      breakdowns: @breakdowns,
      period: params[:period]
    ).call
    render json: @report.to_json
  end
end
