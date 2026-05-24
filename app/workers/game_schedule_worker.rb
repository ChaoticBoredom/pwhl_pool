class GameScheduleWorker
  include Sidekiq::Worker

  def perform
    games = League::Game.where(start_time: Time.now..24.hours.from_now)

    games.each do |g|
      GameUpdateWorker.perform_at(g.start_time - 5.minutes, g.id)
    end
  end
end
