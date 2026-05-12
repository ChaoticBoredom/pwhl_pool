# app/services/box_generation/config.rb
module BoxGeneration
  DEFAULT_BOXES = [
    BoxDefinition.new(name: "Forwards Box 1", position: "F", rank: 1, count: 1),
    BoxDefinition.new(name: "Forwards Box 2", position: "F", rank: 2, count: 1),
    BoxDefinition.new(name: "Forwards Box 3", position: "F", rank: 3, count: 1),
    BoxDefinition.new(name: "Forwards Box 4", position: "F", rank: 4, count: 1),
    BoxDefinition.new(name: "Forwards Box 5", position: "F", rank: 5, count: 1),
    BoxDefinition.new(name: "Defence Box 1", position: "D", rank: 1, count: 1),
    BoxDefinition.new(name: "Defence Box 2", position: "D", rank: 2, count: 1),
    BoxDefinition.new(name: "Defence Box 3", position: "D", rank: 3, count: 1),
    BoxDefinition.new(name: "Goalies Box 1", position: "G", rookie: nil, rank: 1, count: 1),
    BoxDefinition.new(name: "Rookie Forwards Box 1", position: "F", rookie: true, rank: 1, count: 1),
    BoxDefinition.new(name: "Rookie Defence Box 1", position: "D", rookie: true, rank: 1, count: 1),
  ].freeze

  Config = Data.define(:teams, :scope, :boxes, :excluded_player_ids) do
    def initialize(
      teams: nil,
      scope: :per_team,
      boxes: BoxGeneration::DEFAULT_BOXES,
      excluded_player_ids: []
    )
      super
    end

    def per_team?
      scope.to_sym == :per_team
    end

    def global?
      scope.to_sym == :global
    end
  end
end
