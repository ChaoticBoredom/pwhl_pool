class Pool < ApplicationRecord
  validates :name, :pool_type, presence: true

  belongs_to :league
  belongs_to :admin, class_name: "User"

  has_many :scoring, class_name: "Pool::Scoring"
  has_many :pool_teams, class_name: "Pool::Team"
  has_many :pool_boxes, class_name: "Pool::Box"

  enum :pool_type, {
    box_select: 100,
    draft: 200,
  }

  def start_end_range
    Rails.cache.fetch("#{cache_key_with_version}/first_last_game", expires_in: 3.days) do
      start_time, end_time = League::Game.where(league_id: league_id, season_id: season_id).pluck(:start_time).minmax
      start_time.beginning_of_day..end_time.end_of_day
    end
  end
end
