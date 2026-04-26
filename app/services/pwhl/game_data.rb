class Pwhl::GameData
  def initialize
    @pwhl = League.find_by(short_name: "PWHL")
    @teams = League::Team.where(league: @pwhl).to_h { |t| [t.api_id, t] }
  end

  def update_live_game(game_id)
    game = League::Game.find(game_id)

    res = Connections::ConnectionHelper.pwhl_connection.get(nil,
      {
        feed: "gc",
        tab: "gamesummary",
        game_id: game.api_id,
        site_id: 0,
        lang: "eng",
      }
    )

    data = JSON.parse(res.body).dig("GC", "Gamesummary")

    # TODO: Add game status to Game and update here
    # game.status = data.fetch("status")

    update_game_data(game_id, data.fetch("meta"))

    ["home_team_lineup", "visitor_team_lineup"].each do |t|
      current_team = @teams[data.dig(t.split("_").first, "id")]
      data.dig(t, "goalies").each do |goalie_data|
        # Goalies have extra data in a whole field of their own, and it isn't always populated at first :(
        additional_data = data.dig("goalies", t.split("_").first) || []
        additional_data = additional_data.select { |r| r.fetch("player_id", -1) == goalie_data.fetch("player_id", 0) }.first || {}
        player = find_or_create_player(goalie_data, "goalie", current_team)
        rec = Pwhl::GoalieStat.find_or_initialize_by(
          league_player: player,
          league_game_id: game.id,
          league_team: current_team
        )

        # Reverse merge, additional_data is per period but has win/shutout info
        rec = update_goalie_data(rec, goalie_data.reverse_merge(additional_data))
        rec.save!
      end

      data.dig(t, "players").each do |player_data|
        player = find_or_create_player(player_data, "skater", current_team)
        rec = Pwhl::SkaterStat.find_or_initialize_by(
          league_player: player,
          league_game_id: game.id,
          league_team: @teams[data.dig(t.split("_").first, "id")]
        )

        rec = update_skater_data(rec, player_data)
        rec.save!
      end
    end
  end

  def update_game_data(game_id, game_data = nil)
    # 0 information, how're we supposed to do anything?!?
    return if game_id.nil? && game_data.nil?

    if game_id.nil?
      game = League::Game.find_or_initialize_by(
        league: @pwhl,
        api_id: game_data["id"],
        season_id: game_data["season_id"]
      )
    else
      game = League::Game.find(game_id)
    end

    if game_data.nil?
      res = Connections::ConnectionHelper.pwhl_connection.get(nil,
        {
          feed: "gc",
          tab: "gamesummary",
          game_id: game.api_id,
          site_id: 0,
          lang: "eng",
        }
      )
      start_time = JSON.parse(res.body).dig("GC", "Gamesummary").fetch("game_date_iso_8601")

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
      # Game is over, stats folks are verifying shit
      :pending_final
    else
      :final
    end

    # ISO start time is slightly different, try this to grab it
    start_time ||= game_data.fetch("GameDateISO8601", nil)
    start_time ||= DateTime.parse("#{game_data.fetch("date_played", nil)} #{game_data.fetch("schedule_time", nil)} #{game_data.fetch("timezone_short", nil)}")

    game.league = @pwhl
    game.api_id = game_data["id"]
    game.season_id = game_data["season_id"]
    game.start_time = start_time
    game.home_team = @teams[game_data["home_team"]]
    game.away_team = @teams[game_data["visiting_team"]]
    game.status = status
    game.home_team_score = game_data["home_goal_count"]
    game.away_team_score = game_data["visiting_goal_count"]

    game.save
  end

  def update_player_game_data(player_id, game_id, game_data = nil)
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

    rec.league_team ||= @teams[game_data["player_team"]]

    if player.is_a?(Pwhl::Skater)
      rec = update_skater_data(rec, game_data)
    else
      rec = update_goalie_data(rec, game_data)
    end
    rec.save!
  end

  private

  def find_or_create_player(data, position, team)
    League::Player.find_or_create_by(api_id: data.fetch("player_id")) do |player|
      player.name = data.values_at("first_name", "last_name").join(" ")
      player.position = position
      player.league = @pwhl
      player.current_team = team
    end
  end

  def update_goalie_data(rec, data)
    rec.goals = data.fetch("goals", 0)
    rec.assists = data.fetch("assists", 0)

    rec.win = data.fetch("win", 0) == "1"
    rec.shutout = data.fetch("shutout", 0) == "1"
    rec.saves = data.fetch("saves", 0)
    rec.goals_against = data.fetch("goals_against", 0)
    rec.shots_against = data.fetch("shots_against", 0)
    rec.penalty_minutes = data.fetch("pim", 0).to_i.minutes
    rec.time_on_ice = parse_time(data.fetch("minutes"))

    rec
  end

  def update_skater_data(rec, data)
    rec.goals = data.fetch("goals", 0)
    rec.assists = data.fetch("assists", 0)

    rec.penalty_minutes = data.fetch("penalty_minutes", 0).to_i.minutes
    rec.shots = data.fetch("shots", 0)
    rec.hits = data.fetch("hits", 0)
    rec.time_on_ice = parse_time(data.fetch("ice_time_minutes_seconds"))
    rec.plus_minus = data.fetch("plusminus", 0).to_i
    rec.power_play_goals = data.fetch("power_play_goals", 0)
    rec.short_handed_goals = data.fetch("short_handed_goals", 0)
    rec.shots_blocked = data.fetch("shots_blocked_by_player", 0)
    # Different endpoints have different labels >:(
    rec.faceoffs_taken = data.fetch("faceoffs_taken", data.fetch("faceoff_attempts", 0))
    rec.faceoffs_won = data.fetch("faceoffs_won", data.fetch("faceoff_wins", 0))

    rec
  end

  def parse_time(time)
    minutes, seconds = time.split(":").map(&:to_i)

    minutes.minutes + seconds.seconds
  end
end
