namespace :pwhl do
  desc "Add all PWHL data for season"
  task :add_pwhl, [:season] => [:environment] do |t, args|
    Rake::Task["pwhl:add_league"].invoke
    Rake::Task["pwhl:add_teams"].invoke(args.season)
    Rake::Task["pwhl:add_all_players"].invoke(args.season)
    Rake::Task["pwhl:add_all_games"].invoke(args.season)
    Rake::Task["pwhl:add_per_game_stats"].invoke(args.season)
  end


  desc "Add inital PWHL league"
  task add_league: :environment do
    l = League.find_or_create_by(name: "Professional Women's Hockey League", short_name: "PWHL")
  end

  desc "Add PWHL teams"
  task :add_teams, [:season] => [:environment] do |t, args|
    l = League.find_by(short_name: "PWHL")
    res = Connections::ConnectionHelper.pwhl_connection.get(nil,
      {
        feed: "modulekit",
        view: "teamsbyseason",
        season_id: args.season,
      }
    )

    teams = JSON.parse(res.body).dig("SiteKit", "Teamsbyseason")
    teams.each do |team|
      League::Team.find_or_create_by(
        api_id: team["id"],
        league: l,
        name: team["name"],
        short_code: team["code"],
      )
    end
  end

  desc "Add all PWHL Players to the database"
  task :add_all_players, [:season] => [:environment] do |t, args|
    Rake::Task["pwhl:add_all_skaters"].invoke(args.season)
    Rake::Task["pwhl:add_all_goalies"].invoke(args.season)
  end

  desc "Add all PWHL Skaters to the database"
  task :add_all_skaters, [:season] => [:environment] do |t, args|
    Rake::Task["pwhl:add_players"].invoke(0, "skater", args.season)
    Rake::Task["pwhl:add_players"].reenable
  end

  desc "Add all PWHL Goalies to the database"
  task :add_all_goalies, [:season] => [:environment] do |t, args|
    Rake::Task["pwhl:add_players"].invoke(0, "goalie", args.season)
    Rake::Task["pwhl:add_players"].reenable
  end

  desc "Generic task to add PWHL players"
  task :add_players, [:rookies, :position, :season] => [:environment] do |t, args|
    res = Connections::ConnectionHelper.pwhl_connection.get(nil,
      {
        feed: "statviewfeed",
        view: "players",
        season: args.season,
        team: "all",
        position: args.position.pluralize,
        rookies: args.rookies,
        statsType: "standard",
        leadue_id: 1,
        limit: 1000,
        sort: "points",
        lang: "en",
      }
    )
    # Returned JSON is malformed, trim it, and dig to get the actual player data
    players = JSON.parse(res.body[1..-2]).first["sections"].first["data"]

    league = League.find_by(short_name: "PWHL")
    teams = League::Team.where(league: league)

    players.each do |p|
      begin
        pl = League::Player.find_or_create_by(
          league: league,
          api_id: p.dig("row", "player_id"),
        )
        pl.name = p.dig("row", "name")
        pl.position = args.position
        pl.current_team = teams.select { |t| t.short_code == p.dig("row", "team_code") }.first
        pl.save!
      rescue => e
        puts p.dig("row", "player_id"), p.dig("row", "name")
        puts e
      end
    end
  end

  task clear_all_players: [:environment] do
    league = League.find_by(short_name: "PWHL")
    League::Player.where(league: league).destroy_all
  end

  desc "Add all scheduled PWHL games to the database"
  task :add_all_games, [:season] => [:environment] do |t, args|
    res = Connections::ConnectionHelper.pwhl_connection.get(nil,
      {
        feed: "modulekit",
        view: "schedule",
        season_id: args.season,
      }
    )

    league = League.find_by(short_name: "PWHL")

    games = JSON.parse(res.body).dig("SiteKit", "Schedule")
    teams = League::Team.all.to_h { |team| [team.short_code, team] }
    games.each do |g|
      Pwhl::GameData.update_game_data(nil, g)
    end
  end

  desc "Remove all PWHL games to the database"
  task :remove_all_games, [:season] => [:environment] do |t, args|
    league = League.find_by(short_name: "PWHL")
    LeagueGame.where(league: league, season_id: args.season).destroy_all
  end

  desc "Add game by game stats for all players"
  task :add_per_game_stats, [:season] => [:environment] do |t, args|
    pwhl = League.find_by(short_name: "PWHL")
    teams = League::Team.where(league: pwhl)
    League::Player.where(league: pwhl).each do |p|
      res = Connections::ConnectionHelper.pwhl_connection.get(nil,
        {
          feed: "modulekit",
          view: "player",
          category: "gamebygame",
          season_id: args.season,
          player_id: p.api_id,
        }
      )
      games = JSON.parse(res.body).dig("SiteKit", "Player", "games")
      puts "Importing data from #{games.count} games for player #{p.api_id}..."
      games.each do |g|
        lg = League::Game.find_by(api_id: g["id"], league: pwhl)

        Pwhl::GameData.update_player_game_data(p.id, lg.id, g)
      end
    end
  end
end
