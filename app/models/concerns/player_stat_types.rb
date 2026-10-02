module PlayerStatTypes
  extend ActiveSupport::Concern

  included do
    enum :stat_type, {
      skater: 100,
      goalie: 200,
    }, validate: true
  end
end
