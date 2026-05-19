require "csv"

namespace :one_offs do
  desc "Import trade data from officepools export"
  task :import_trades, [:file_path, :pool_id] => :environment do |t, args|
    path = args[:file_path]
    pool_id = args[:pool_id]

    if path.nil?
      puts "File Path is required for import"
      next
    end

    if pool_id.nil?
      puts "Pool id is required for import"
      next
    end

    pool = Pool.find(args[:pool_id])
    if pool.nil?
      puts "Pool not found, please specify a valid pool_id"
      next
    end

    data = CSV.read(path, headers: true)

    teams = data["Team"].uniq
    boxes = data["Round"].uniq

    data["Player"] = data["Player/Franchise"].map { |p| p.split(", ").reverse.join(" ") }
    data["Released"] = data["Released"].map { |r| Time.strptime(r, "%Y-%m-%d") }
    data["Acquired"] = data["Acquired"].map { |r| Time.strptime(r, "%Y-%m-%d") }

    teams.each.with_index do |t, i|
      user = User.find_or_create_by(email_address: "trade_team#{i}@trader.com") do |u|
        u.name = "#{t} Owner"
        u.password = "tester1"
      end

      team = Pool::Team.find_or_create_by(team_name: t, user: user, pool: pool)

      boxes.each do |b|
        data.
          select { |row| row["Team"] == t && row["Round"] == b }.
          pluck("Player", "Acquired", "Released").
          sort { |r| r[1] }.each do |player_name, acq, rel|
            next if player_name == "Alexie Guay" # Rookie who was a choice, but did not play this season

            player = League::Player.find_by(name: player_name)

            team.pool_team_players.find_or_create_by(league_player: player, added_at: acq) do |tp|
              tp.dropped_at = rel unless rel.future?
            end
          end
      end

      puts "Loaded #{t} trade history"
    end
  end
end
