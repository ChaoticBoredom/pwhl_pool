class Pool::TradeWindow < ApplicationRecord
  validates :open_window, presence: true

  belongs_to :pool

  scope :current, -> { where("open_window @> ?::timestamptz", Time.current) }
end
