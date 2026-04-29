class UpcomingGamesService
  def player_schedule(team_players)
    return {} if team_players.empty?

    team_ids = team_players.to_h { |v| [v.id, v.current_team_id] }
    teams = League::Team.where(id: team_ids.values.uniq)

    team_game_hash = teams.each_with_object({}) do |t, r_hash|
      r_hash[t.id] = { upcoming: t.next_game, today: t.todays_game }
    end

    team_ids.transform_values { |v| team_game_hash[v] }
  end
end
