class League < ApplicationRecord
  validates :name, presence: true

  has_many :games, class_name: "League::Game"

  def first_game_today
    Rails.cache.fetch("#{cache_key_with_version}/first_game/#{Date.today}", expires_in: 2.hours) do
      games.where(start_time: Time.current.all_day).minimum(:start_time)
    end
  end

  def games_started?
    first_time = first_game_today
    first_time.present? && Time.current >= first_time
  end
end
