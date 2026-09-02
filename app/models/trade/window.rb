class Trade::Window < ApplicationRecord
  validates :open_window, presence: true
  validate :open_window_start_before_end

  belongs_to :pool

  scope :current, -> { where("open_window @> ?::timestamptz", Time.current) }

  private

  def open_window_start_before_end
    # Validations do not short circuit, need to ensure this is set or will throw unrelated errors
    return if open_window.nil?

    errors.add(:open_window, "start must be before end") if open_window.begin >= open_window.end
  end
end
