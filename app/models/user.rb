class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  has_many :pool_teams, class_name: "Pool::Team", dependent: :destroy

  validates :email_address, presence: true, uniqueness: true
  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
