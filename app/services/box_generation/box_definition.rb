module BoxGeneration
  BoxDefinition = Data.define(:name, :position, :rookie, :rank, :count) do
    def initialize(name:, position:, rookie: false, rank: 1, count: 1)
      super
    end

    def rank_range
      start = rank - 1
      (start..start + count - 1)
    end
  end
end
