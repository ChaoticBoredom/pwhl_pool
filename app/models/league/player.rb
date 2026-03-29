class League::Player < ApplicationRecord
  include PlayerPositions

  belongs_to :league
  belongs_to :current_team, class_name: "League::Team"

  def initialize(attributes = nil)
    super
    if league && position
      self.type = "#{league.short_name.classify}::#{position.classify}"
    end
  end

  def self.inherited(subclass)
    super
  end

  def self.find_sti_class(type_name)
    if type_name.include?("::")
      type_name.constantize
    else
      super
    end
  end
end
