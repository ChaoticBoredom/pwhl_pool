module PlayerRosterTypes
  extend ActiveSupport::Concern

  included do
    enum :roster_type, {
      skater: 100,
      goalie: 200,
    }, validate: true
  end
end
