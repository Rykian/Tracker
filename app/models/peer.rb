# Peer model - Active peer connections with state tracking
#
# Represents a BitTorrent client connected to the tracker for a specific torrent.
# Peers are considered active if they've announced within the last hour.
#
# Lifecycle:
#   - Created/updated on /announce requests
#   - Deleted by CleanupStalePeersJob after 1 hour of inactivity
#
class Peer < ApplicationRecord
  belongs_to :torrent
  belongs_to :user

  validates :peer_id, presence: true, length: { is: 20 }
  validates :ip, presence: true, format: { with: /\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\z/ }
  validates :port, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 65535 }
  validates :left, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :uploaded, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :downloaded, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :event, inclusion: { in: %w[started completed stopped], allow_nil: true }
  validates :last_announce, presence: true

  scope :active, -> { where("last_announce > ?", 1.hour.ago) }
  scope :seeders, -> { where(left: 0) }
  scope :leechers, -> { where('"peers"."left" > ?', 0) }

  # Returns true if peer has completed the download (left = 0)
  #
  # @return [Boolean] True if peer is a seeder, false otherwise
  def seeder?
    left.zero?
  end

  # Returns true if peer is still downloading (left > 0)
  #
  # @return [Boolean] True if peer is a leecher, false otherwise
  def leecher?
    left > 0
  end
end
