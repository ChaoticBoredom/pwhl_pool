class League::Team < ApplicationRecord
  validates :api_id, :name, presence: :true

  belongs_to :league

  has_many :players, class_name: "League::Player", foreign_key: "current_team_id"

  has_many :away_games, class_name: "League::Game", foreign_key: "away_team_id"
  has_many :home_games, class_name: "League::Game", foreign_key: "home_team_id"

  after_update :invalidate_short_code_cache, if: :short_code_previously_changed?

  def self.short_codes_by_league(league_id)
    Rails.cache.fetch("league/#{league_id}/team_short_codes", expires_in: 1.hour) do
      where(league_id: league_id).pluck(:id, :short_code).to_h
    end
  end

  def all_games
    home_games.or(away_games)
  end

  def todays_game
    Rails.cache.fetch(["todays_game", id, Time.zone.today.to_s]) do
      all_games.where(start_time: Time.current.all_day).first&.attributes
    end&.then { |attrs| League::Game.instantiate(attrs) }
  end

  def next_game
    Rails.cache.fetch(["next_game", id, Time.zone.today.to_s]) do
      all_games.where(start_time: 1.day.from_now..).first&.attributes
    end&.then { |attrs| League::Game.instantiate(attrs) }
  end

  private

  def invalidate_short_code_cache
    Rails.cache.delete("league/#{league_id}/team_short_codes")
  end
end
