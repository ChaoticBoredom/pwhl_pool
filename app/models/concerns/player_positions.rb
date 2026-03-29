module PlayerPositions
  extend ActiveSupport::Concern

  included do
    enum :position, {
      skater: 100,
      goalie: 200,
    }, validate: true
  end
end
