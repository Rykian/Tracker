# User model - Tracker users with authentication and statistics
#
# Represents authenticated users who can upload torrents and participate
# as peers in the BitTorrent swarm.
#
class User < ApplicationRecord
  has_secure_password
  has_many :torrents, dependent: :destroy
  has_many :peers, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }

  # Calculates upload/download ratio
  #
  # @return [nil, Float::INFINITY, Float] Upload/download ratio or nil if both are zero
  #   - nil if both uploaded and downloaded are zero
  #   - Float::INFINITY if downloaded is zero and uploaded is positive
  #   - 0.0 if uploaded is zero
  #   - Float rounded to 2 places otherwise
  def ratio
    return nil if uploaded.zero? && downloaded.zero?
    return Float::INFINITY if downloaded.zero? && uploaded.positive?
    return 0.0 if uploaded.zero?

    (uploaded.to_f / downloaded).round(2)
  end

  # Atomically updates user statistics by incrementing uploaded and downloaded counts
  #
  # @param uploaded_delta [Integer] Number of bytes to add to uploaded count
  # @param downloaded_delta [Integer] Number of bytes to add to downloaded count
  # @return [void]
  # @note Uses atomic increment operations to avoid race conditions
  def update_stats!(uploaded_delta, downloaded_delta)
    increment!(:uploaded, uploaded_delta)
    increment!(:downloaded, downloaded_delta)
  end
end
