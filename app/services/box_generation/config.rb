module BoxGeneration
  DEFAULT_BOXES = [
    BoxDefinition.new(name: "Forwards Box 1", position: "F", rank_range: 0..0),
    BoxDefinition.new(name: "Forwards Box 2", position: "F", rank_range: 1..1),
    BoxDefinition.new(name: "Forwards Box 3", position: "F", rank_range: 2..2),
    BoxDefinition.new(name: "Forwards Box 4", position: "F", rank_range: 3..3),
    BoxDefinition.new(name: "Forwards Box 5", position: "F", rank_range: 4..4),

    BoxDefinition.new(name: "Defense Box 1", position: "D", rank_range: 0..0),
    BoxDefinition.new(name: "Defense Box 2", position: "D", rank_range: 1..1),
    BoxDefinition.new(name: "Defense Box 3", position: "D", rank_range: 2..2),

    BoxDefinition.new(name: "Goalies Box 1", position: "G", rookie: nil, rank_range: 0..0),

    BoxDefinition.new(name: "Rookie Forwards Box 1", position: "F", rookie: true, rank_range: 0..0),
    BoxDefinition.new(name: "Rookie Defense Box 1", position: "D", rookie: true, rank_range: 0..0),
  ].freeze

  Config = Data.define(:season_id, :teams, :max_players_per_team, :boxes, :excluded_player_ids) do
    def initialize(
      season_id:,
      teams: nil,
      max_players_per_team: 1,
      boxes: DEFAULT_BOXES,
      excluded_player_ids: [])
      super
    end
  end
end
