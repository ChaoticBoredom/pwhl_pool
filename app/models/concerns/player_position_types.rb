module PlayerPositionTypes
  extend ActiveSupport::Concern

  GROUP_NAMES = {
    "F" => :forward,
    "D" => :defense,
    "G" => :goalie,
  }.freeze

  included do
    enum :position_type, {
      wildcard: 0,
      ir: 1,
      forward: 10,
      defense: 20,
      goalie: 30,
    }, validate: true
  end

  class_methods do
    def position_type_for(league_player)
      position_groups = league_player.league.stat_config::POSITION_GROUPS
      group = position_groups.find { |_group, codes| codes.include?(league_player.position) }&.first

      raise KeyError, "No position group for #{league_player.position.inspect} in #{league.short_name}" unless group

      GROUP_NAMES.fetch(group) do
        raise KeyError, "No position_type mapping for group #{group.inspect}"
      end
    end
  end
end
