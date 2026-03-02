class Pool::Box < ApplicationRecord
  validates :name, presence: true

  belongs_to :pool
end
