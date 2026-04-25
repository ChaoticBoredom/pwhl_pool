class Pool::Box < ApplicationRecord
  validates :name, presence: true
  validates :name, uniqueness: { scope: :pool_id, message: "all pool box names must be unique" }

  belongs_to :pool
  positioned on: :pool

  def players
    @players ||= League::Player.where(id: league_player_ids)
  end
end
