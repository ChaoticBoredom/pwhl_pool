class GameUpdater
  include Sidekiq::Worker

  def perform(game_id)
    game = League::Game.find(game_id)

    Pwhl::GameData.new.update_live_game(game_id)

    # Run the update again if it isn't over yet!
    GameUpdater.perform_in(1.minute, game_id) unless game.final?
  end
end
