module BoxGeneration
  Config = Data.define(:teams, :scope, :boxes, :excluded_player_ids) do
    def initialize(teams: nil, scope: :per_team, boxes: nil, excluded_player_ids: [])
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
