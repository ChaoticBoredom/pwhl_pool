module BoxGeneration
  BoxDefinition = Data.define(:name, :position, :rookie, :rank_range) do
    def initialize(name:, position:, rookie: false, rank_range: 0..0)
      super
    end
  end
end
