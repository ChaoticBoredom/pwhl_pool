module PlayerPositionCategories
  extend ActiveSupport::Concern

  included do
    enum :position_category, {
      # PWHL positions
      pwhl_f: 101, pwhl_d: 102, pwhl_g: 103
    }, validate: true
  end

  class_methods do
    def position_category_for(league_player)
      league = league_player.league
      position_groups = league.stat_config::POSITION_GROUPS
      group = position_groups.find { |_group, codes| codes.include?(league_player.position) }&.first

      raise KeyError, "No position group for #{league_player.position.inspect} in #{league.short_name}" unless group

      :"#{league.short_name.downcase}_#{group.downcase}"
    end
  end
end
