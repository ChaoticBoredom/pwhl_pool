# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_24_111106) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "league_games", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "api_id", null: false
    t.uuid "away_team_id", null: false
    t.integer "away_team_score"
    t.datetime "created_at", null: false
    t.uuid "home_team_id", null: false
    t.integer "home_team_score"
    t.uuid "league_id", null: false
    t.string "season_id", null: false
    t.timestamptz "start_time", null: false
    t.integer "status"
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["api_id", "league_id"], name: "index_league_games_on_api_id_and_league_id", unique: true
    t.index ["away_team_id"], name: "index_league_games_on_away_team_id"
    t.index ["home_team_id"], name: "index_league_games_on_home_team_id"
    t.index ["league_id"], name: "index_league_games_on_league_id"
  end

  create_table "league_players", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "api_id", null: false
    t.datetime "created_at", null: false
    t.uuid "current_team_id"
    t.uuid "league_id", null: false
    t.string "name", null: false
    t.integer "position", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["api_id", "league_id"], name: "index_league_players_on_api_id_and_league_id", unique: true
    t.index ["current_team_id"], name: "index_league_players_on_current_team_id"
    t.index ["league_id"], name: "index_league_players_on_league_id"
  end

  create_table "league_teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "api_id", null: false
    t.datetime "created_at", null: false
    t.uuid "league_id", null: false
    t.string "name", null: false
    t.string "short_code"
    t.datetime "updated_at", null: false
    t.index ["api_id", "league_id"], name: "index_league_teams_on_api_id_and_league_id", unique: true
    t.index ["league_id"], name: "index_league_teams_on_league_id"
  end

  create_table "leagues", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "short_name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_leagues_on_name", unique: true
  end

  create_table "pool_boxes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "league_player_ids", default: [], null: false, array: true
    t.string "name", null: false
    t.uuid "pool_id", null: false
    t.datetime "updated_at", null: false
    t.index ["league_player_ids"], name: "index_pool_boxes_on_league_player_ids", using: :gin
    t.index ["pool_id"], name: "index_pool_boxes_on_pool_id"
  end

  create_table "pool_scorings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "field_name", null: false
    t.uuid "pool_id", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.float "value", null: false
    t.index ["pool_id", "field_name", "position"], name: "index_pool_scorings_on_pool_id_and_field_name_and_position", unique: true
    t.index ["pool_id"], name: "index_pool_scorings_on_pool_id"
  end

  create_table "pool_team_players", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "added_at", precision: nil, null: false
    t.datetime "created_at", null: false
    t.datetime "dropped_at", precision: nil
    t.uuid "league_player_id", null: false
    t.uuid "pool_id", null: false
    t.uuid "pool_team_id", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.index ["league_player_id"], name: "index_pool_team_players_on_league_player_id"
    t.index ["pool_team_id", "league_player_id"], name: "index_unique_active_player_per_team", unique: true, where: "(dropped_at IS NULL)"
    t.index ["pool_team_id"], name: "index_pool_team_players_on_pool_team_id"
  end

  create_table "pool_teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "pool_id", null: false
    t.string "team_name", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["pool_id", "user_id"], name: "index_pool_teams_on_pool_id_and_user_id", unique: true
    t.index ["pool_id"], name: "index_pool_teams_on_pool_id"
    t.index ["user_id"], name: "index_pool_teams_on_user_id"
  end

  create_table "pools", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "admin_id", null: false
    t.datetime "created_at", null: false
    t.uuid "league_id", null: false
    t.string "name", null: false
    t.integer "pool_type", null: false
    t.string "reference_season_id"
    t.string "season_id", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_pools_on_admin_id"
    t.index ["league_id"], name: "index_pools_on_league_id"
    t.check_constraint "reference_season_id::text <> season_id::text", name: "pools_reference_season_differs_from_season"
  end

  create_table "pwhl_goalie_stats", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "assists", null: false
    t.datetime "created_at", null: false
    t.integer "goals", null: false
    t.integer "goals_against", null: false
    t.uuid "league_game_id", null: false
    t.uuid "league_player_id", null: false
    t.uuid "league_team_id", null: false
    t.interval "penalty_minutes", null: false
    t.integer "saves", null: false
    t.integer "shots_against", null: false
    t.boolean "shutout", null: false
    t.interval "time_on_ice", null: false
    t.datetime "updated_at", null: false
    t.boolean "win", null: false
    t.index ["league_game_id"], name: "index_pwhl_goalie_stats_on_league_game_id"
    t.index ["league_player_id", "league_game_id"], name: "index_goalie_stats_on_player_and_game"
    t.index ["league_player_id", "league_game_id"], name: "index_pwhl_goalie_stats_on_league_player_id_and_league_game_id", unique: true
    t.index ["league_player_id"], name: "index_pwhl_goalie_stats_on_league_player_id"
    t.index ["league_team_id"], name: "index_pwhl_goalie_stats_on_league_team_id"
  end

  create_table "pwhl_skater_stats", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "assists", null: false
    t.datetime "created_at", null: false
    t.integer "faceoffs_taken", null: false
    t.integer "faceoffs_won", null: false
    t.integer "goals", null: false
    t.integer "hits", null: false
    t.uuid "league_game_id", null: false
    t.uuid "league_player_id", null: false
    t.uuid "league_team_id", null: false
    t.interval "penalty_minutes", null: false
    t.integer "plus_minus", null: false
    t.integer "power_play_goals", null: false
    t.integer "short_handed_goals", null: false
    t.integer "shots", null: false
    t.integer "shots_blocked", null: false
    t.interval "time_on_ice", null: false
    t.datetime "updated_at", null: false
    t.index ["league_game_id"], name: "index_pwhl_skater_stats_on_league_game_id"
    t.index ["league_player_id", "league_game_id"], name: "index_pwhl_skater_stats_on_league_player_id_and_league_game_id", unique: true
    t.index ["league_player_id", "league_game_id"], name: "index_skater_stats_on_player_and_game"
    t.index ["league_player_id"], name: "index_pwhl_skater_stats_on_league_player_id"
    t.index ["league_team_id"], name: "index_pwhl_skater_stats_on_league_team_id"
  end

  create_table "sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.string "token"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.uuid "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "league_games", "league_teams", column: "away_team_id"
  add_foreign_key "league_games", "league_teams", column: "home_team_id"
  add_foreign_key "league_games", "leagues"
  add_foreign_key "league_players", "league_teams", column: "current_team_id"
  add_foreign_key "league_players", "leagues"
  add_foreign_key "league_teams", "leagues"
  add_foreign_key "pool_boxes", "pools"
  add_foreign_key "pool_scorings", "pools"
  add_foreign_key "pool_team_players", "league_players"
  add_foreign_key "pool_team_players", "pool_teams"
  add_foreign_key "pool_teams", "pools"
  add_foreign_key "pool_teams", "users"
  add_foreign_key "pools", "leagues"
  add_foreign_key "pools", "users", column: "admin_id"
  add_foreign_key "pwhl_goalie_stats", "league_games"
  add_foreign_key "pwhl_goalie_stats", "league_players"
  add_foreign_key "pwhl_goalie_stats", "league_teams"
  add_foreign_key "pwhl_skater_stats", "league_games"
  add_foreign_key "pwhl_skater_stats", "league_players"
  add_foreign_key "pwhl_skater_stats", "league_teams"
  add_foreign_key "sessions", "users"
end
