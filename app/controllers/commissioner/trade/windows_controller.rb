class Commissioner::Trade::WindowsController < Commissioner::BaseController
  before_action :require_windowed_trade_policy
  before_action :load_window, only: [:update, :destroy]

  def index
    @trade_windows = @pool.trade_windows.order(open_window: :asc)
    render :index
  end

  def create
    @trade_window = @pool.trade_windows.create!(open_window: window_range)

    render :show, status: :created
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def update
    @trade_window.update!(open_window: window_range)

    render :show
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def destroy
    @trade_window.destroy!

    head :no_content
  end

  private

  def require_windowed_trade_policy
    unless @pool.trade_policy_windowed? || @pool.trade_policy_windowed_overflow?
      head :forbidden
    end
  end

  def load_window
    @trade_window = @pool.trade_windows.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def window_range
    Range.new(
      parse_time!("open_window_start"),
      parse_time!("open_window_end"),
    )
  end

  def parse_time!(field_name)
    value = params[field_name]
    raise ArgumentError, "#{field_name} is required" if value.blank?

    Time.zone.parse(value) || raise(ArgumentError, "#{field_name} is not a valid time")
  end
end
