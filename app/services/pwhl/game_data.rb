class Pwhl::GameData
  def self.update_game_data(game_id, game_data = nil)
    @pwhl ||= League.find_by(short_name: "PWHL")
    @teams ||= League::Team.where(league: @pwhl).to_h { |team| [team.api_id, team] }

    # 0 information, how're we supposed to do anything?!?
    return if game_id.nil? && game_data.nil?

    if game_id.nil?
      game = League::Game.find_by(
        league: @pwhl,
        api_id: game_data["id"],
        season_id: game_data["season_id"]
      )
    end

    if game_data.nil?
      game = League::Game.find(id: game_id)
      res = Connections::ConnectionHelper.pwhl_connection.get(nil,
        {
          feed: "gc",
          tab: "gamesummary",
          game_id: game.api_id,
          site_id: 0,
          lang: "eng",
        }
      )

      game_data = JSON.parse(res.body).dig("GC", "Gamesummary", "meta")
    end

    status_codes = [
      game_data["started"],
      game_data.fetch("pending_final", "0"),
      game_data["final"],
    ]

    status = case status_codes
    when ["0", "0", "0"]
      :scheduled
    when ["1", "0", "0"]
      :in_progress
    when ["1", "1", "0"]
      :pending
    else
      :final
    end

    game.league = @pwhl
    game.api_id = game_data["id"]
    game.season_id = game_data["season_id"]
    game.date = game_data["date_played"]
    game.home_team = @teams[game_data["home_team"]]
    game.away_team = @teams[game_data["visiting_team"]]
    game.status = status
    game.home_team_score = game_data["home_goal_count"]
    game.away_team_score = game_data["visiting_goal_count"]

    game.save
  end

  def self.update_player_game_data(player_id, game_id, game_data = nil)
    @pwhl ||= League.find_by(short_name: "PWHL")
    @teams ||= League::Team.where(league: @pwhl).to_h { |team| [team.api_id, team] }

    player = League::Player.find(player_id)
    game = League::Game.find(game_id)

    if game_data.nil?
      res = Connections::ConnectionHelper.pwhl_connection.get(nil,
        {
          feed: "modulekit",
          view: "player",
          category: "gamebygame",
          season_id: game.season_id,
          player_id: player.api_id,
        }
      )

      games = JSON.parse(res.body).dig("SiteKit", "Player", "games")

      game_data = games.find { |g| g["id"] == game.api_id }
    end

    rec = player.records.find_or_initialize_by(league_game: game)

    rec.goals = game_data["goals"]
    rec.assists = game_data["assists"]
    rec.league_team ||= @teams[game_data["player_team"]]

    if player.is_a?(Pwhl::Skater)
      rec.penalty_minutes = game_data["penalty_minutes"].to_f * 60
      rec.shots = game_data["shots"]
      rec.hits = game_data["hits"]
      rec.time_on_ice = Time.parse("0:#{game_data["ice_time_minutes_seconds"]}").seconds_since_midnight.to_i
      rec.plus_minus = game_data["plus_minus"]
      rec.power_play_goals = game_data["power_play_goals"]
      rec.short_handed_goals = game_data["short_handed_goals"]
      rec.shots_blocked = game_data["shots_blocked_by_player"]
      rec.faceoffs_taken = game_data["faceoffs_taken"]
      rec.faceoffs_won = game_data["faceoffs_won"]
    else
      rec.win = game_data["win"] == "1"
      rec.shutout = game_data["shutout"] == "1"
      rec.saves = game_data["saves"]
      rec.goals_against = game_data["goals_against"]
      rec.shots_against = game_data["shots_against"]
      rec.penalty_minutes = (game_data["penalty_minutes"].presence&.to_f || 0) * 60
      rec.time_on_ice = game_data["seconds_played"].to_i
    end
    rec.save
  end
end
