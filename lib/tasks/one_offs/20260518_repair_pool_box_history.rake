namespace :one_off do
  desc "Repair pool box history for round 1 to round 2 transition (2026-05-18)"
  task :repair_pool_box_history, [:pool_ids] => :environment do |_, args|
    ROUND_1_END   = Time.zone.parse("2026-05-12 23:59:59")
    ROUND_2_START = Time.zone.parse("2026-05-13 06:00:00")

    # Round 1 box definitions — name => [player_ids]
    ROUND_1_BOXES = {
      "Forwards Box 1" => [
        "4bd5283d-4bd6-48ca-923e-a59d953924a4", # Brianne Jenner
        "d31abf56-aaf5-48a0-b07c-e29897a2ffad", # Taylor Heise
        "99d74898-63e7-4f06-86de-c765e01490a0", # Laura Stacey
        "09aa4534-fb50-4c66-86f5-c681bf275950", # Jessie Eldridge
      ],
      "Forwards Box 2" => [
        "fe50c8f5-1a90-41e6-a953-d61bba4188fb", # Rebecca Leslie
        "b0e1c6e2-2ff8-4b26-b417-e0b738b96884", # Kelly Pannek
        "4abaa844-565c-425d-a84e-c93bdcb73a48", # Marie-Philip Poulin
        "78c695c4-b4c8-4cf1-91a6-ab2e62d65496", # Alina Müller
      ],
      "Forwards Box 3" => [
        "b9d83225-2034-4c87-8df3-f8667b9dc3a2", # Fanuza Kadirova
        "b1c5d0a0-745e-46a0-94f5-648609f44d9b", # Grace Zumwinkle
        "81c7b338-2376-45ee-9be6-9fa747ad196a", # Abby Roque
        "453425e9-975c-49d5-83ea-a242e114d282", # Susanna Tapani
      ],
      "Forwards Box 4" => [
        "a47efe4f-8a6e-454c-a9d9-b63a77c9a560", # Emily Clark
        "244244b9-1395-411d-a8c7-59acb1665972", # Kendall Coyne Schofield
        "f7d5adeb-547c-4b54-b369-be81fceb66d2", # Hayley Scamurra
        "d431e0d0-011c-4fff-b4c4-554021e5e115", # Shay Maloney
      ],
      "Forwards Box 5" => [
        "872fcc36-6b4d-4c7f-ac1c-862cc0bb9dcf", # Gabbie Hughes
        "9199cbbe-dcce-489f-b732-73b89526cb46", # Katy Knoll
        "22217252-7152-4e3a-a59c-6ca81d4493e5", # Shiann Darkangelo
        "d3f0c35c-ed4c-42a2-a145-405708475bdf", # Jamie Lee Rattray
      ],
      "Defense Box 1" => [
        "ebd37db7-d614-408b-a6f3-2f7fc2513176", # Ronja Savolainen
        "e83b8bdd-badb-4ba7-97d9-f4f243432011", # Lee Stecklein
        "bd0d7467-aefd-4167-92cb-440a187c8301", # Kati Tabin
        "11cba5d1-a4a4-4268-9034-a32f7f7d3da3", # Megan Keller
      ],
      "Defense Box 2" => [
        "23f4d387-6419-4376-9cef-17dbfe5d1971", # Jocelyne Larocque
        "4ceec824-5cf5-4fa1-95de-845fa77c5459", # Mae Batherson
        "ddfd0e89-cd3c-4a9b-903b-efd761bc19c3", # Maggie Flaherty
        "4ab9b6e3-e6ee-4c5b-859f-ec8489e805d4", # Daniela Pejšová
      ],
      "Defense Box 3" => [
        "ccb4d79d-9f10-4676-abdc-eda9fcc4b8b4", # Brooke Hobson
        "56cf9690-b129-4619-9c0f-b68769fe54a2", # Sidney Morin
        "afb70f90-4f2c-45c0-a28b-1a162d91a85f", # Jessica DiGirolamo
        "9ed86cbb-8b4e-4a1c-a96a-c1f21ae79a2b", # Rylind MacKinnon
      ],
      "Goalies Box 1" => [
        "3230ea8b-6675-46f7-bb32-4e11ccdbcca2", # Gwyneth Philips
        "422b5c29-853e-4d98-8979-3001017efbb9", # Maddie Rooney
        "d2fbe403-d42a-44a6-a4a7-b06662c67c61", # Ann-Renée Desbiens
        "9dd85e70-1bde-430e-9395-f2433d292fb2", # Aerin Frankel
      ],
      "Rookie Forwards Box 1" => [
        "40ff6e88-b0fc-46a9-9479-379baa7da588", # Sarah Wozniewicz
        "e8e08e48-917e-4098-b79e-a75139ced69e", # Abby Hustler
        "bde60f36-920a-42c7-9c8c-5dfe3e71b5c4", # Natálie Mlýnková
        "9d44b4b2-ea92-4af7-a827-668e593814cf", # Abby Newhook
      ],
      "Rookie Defense Box 1" => [
        "23bfc7b1-2ba0-4013-aafd-ae2eb54f767f", # Rory Guilday
        "7968145e-69d8-4722-90df-85ba52f75d4a", # Kendall Cooper
        "2477435f-0150-4f3c-9c33-d966b462eee6", # Nicole Gosling
        "037728e6-4a29-4c41-b8c1-e54308d242da", # Haley Winn
      ],
    }.freeze

    pool_ids = args[:pool_ids]&.split(",")&.map(&:strip)
    pool_ids ||= [
      "b9a0f505-5b8e-47f4-8e78-b1675dbd8426",
      "3acdfe63-ea55-4985-bddc-910cbaafd7fe",
      "4ae6cbac-87dd-48fb-a2a6-ef3e26b9952a",
    ]

    Pool.where(id: pool_ids).each do |pool|
      puts "\n== Repairing pool: #{pool.name} (#{pool.id}) =="

      # Build player_id -> round 2 box lookup from current boxes
      r2_box_by_player_id = pool.pool_boxes.each_with_object({}) do |pb, hash|
        pb.league_player_ids.each { |pid| hash[pid] = pb }
      end

      ActiveRecord::Base.transaction do
        ROUND_1_BOXES.each do |box_name, player_ids|
          puts "  Creating inactive box: #{box_name}"

          # Find the current (round 2) box with the same name to get position
          r2_box = pool.pool_boxes.find_by(name: box_name)

          r1_box = pool.pool_boxes.create!(
            name: "#{box_name} (Rd 1)",
            league_player_ids: player_ids,
            active: false,
            position: r2_box&.position,
          )

          player_ids.each do |player_id|
            # Find existing active team players for this player in this pool
            existing_tps = Pool::TeamPlayer.joins(:pool_team).
              where(pool_teams: { pool_id: pool.id }).
              where(league_player_id: player_id).
              where(dropped_at: nil)

            existing_tps.each do |tp|
              puts "    Dropping #{tp.id} (player #{player_id}) from active team"
              tp.update!(dropped_at: ROUND_1_END)

              if r2_box_by_player_id[player_id]
                # Player exists in round 2 — create new team player record for round 2
                puts "    Creating round 2 record for player #{player_id}"
                Pool::TeamPlayer.create!(
                  pool_team: tp.pool_team,
                  league_player_id: player_id,
                  pool_box: r2_box_by_player_id[player_id],
                  added_at: ROUND_2_START,
                )
              end
              # If player not in round 2, they were dropped — existing dropped_at stays,
              # we just need to update their pool_box_id to the r1 box
            end

            # For already-dropped players (dropped_at present), update pool_box to r1 box
            Pool::TeamPlayer.joins(:pool_team).
              where(pool_teams: { pool_id: pool.id }).
              where(league_player_id: player_id).
              where.not(dropped_at: nil).
              where("added_at < ?", ROUND_2_START).
              each do |tp|
                puts "    Updating dropped player #{player_id} pool_box to r1 box"
                tp.update!(pool_box: r1_box)
              end
          end
        end
      end

      puts "  Done."
    end

    puts "\nRepair complete."
  end
end
