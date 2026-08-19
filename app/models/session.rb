class Session < ApplicationRecord
  EXCHANGE_CODE_TTL = 60.seconds

  belongs_to :user
  before_create :generate_token

  def self.create_exchange_code_for(session)
    code = SecureRandom.hex(16)
    Rails.cache.write("session_exchange:#{code}", session.token, expires_in: EXCHANGE_CODE_TTL)
    code
  end

  def self.find_by_exchange_code(code)
    token = Rails.cache.read("session_exchange:#{code}")
    return nil unless token

    Rails.cache.delete("session_exchange:#{code}")
    find_by(token: token)
  end

  private

  def generate_token
    self.token = Digest::SHA1.hexdigest([Time.now, rand].join)
  end
end
