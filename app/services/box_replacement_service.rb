class BoxReplacementService
  Result = Data.define(:success, :errors)

  def initialize(pool, boxes_data)
    @pool = pool
    @boxes_data = boxes_data
  end

  def call
    if @pool.pool_state_draft?
      replace_draft
    elsif @pool.pool_state_active?
      replace_active
    else
      Result.new(success: false, errors: ["Boxes cannot be replaced on a #{@pool.state} pool"])
    end
  end

  private

  def replace_draft
    Pool::Box.transaction do
      @pool.pool_boxes.destroy_all
      create_boxes!
    end
    Result.new(success: true, errors: [])
  rescue ActiveRecord::RecordInvalid => e
    Result.new(success: false, errors: [e.message])
  end

  def replace_active
    Pool::Box.transaction do
      @pool.pool_boxes.each { |pb| pb.update!(active: false) }
      create_boxes!
      force_drop_all_players!
    end
    Result.new(success: true, errors: [])
  rescue ActiveRecord::RecordInvalid => e
    Result.new(success: false, errors: [e.message])
  end

  def create_boxes!
    @boxes_data.each do |box|
      player_ids = Array(box[:players]).map { |p| p[:id] }
      @pool.pool_boxes.create!(
        name: box[:name],
        position: box[:position],
        league_player_ids: player_ids,
        active: true,
      )
    end
  end

  def force_drop_all_players!
    Pool::TeamPlayer.
      joins(:pool_team).
      where(pool_id: @pool.id, dropped_at: nil).
      each { |ptp| ptp.update!(dropped_at: Time.current) }
  end
end
