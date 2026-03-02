class League::Team < ApplicationRecord
  validates :api_id, :name, presence: :true

  belongs_to :league

  has_many :players, class_name: "League::Player", foreign_key: "current_team_id"
end
