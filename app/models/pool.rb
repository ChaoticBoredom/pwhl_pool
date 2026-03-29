class Pool < ApplicationRecord
  validates :name, :pool_type, presence: true

  belongs_to :league
  belongs_to :admin, class_name: "User"

  has_many :scoring, class_name: "Pool::Scoring"
  has_many :pool_teams, class_name: "Pool::Team"
  has_many :pool_boxes, class_name: "Pool::Box"

  enum :pool_type, {
    box_select: 100,
    draft: 200,
  }
end
