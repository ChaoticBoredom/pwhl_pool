class Pool::Team < ApplicationRecord
  belongs_to :user
  belongs_to :pool
end
