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

  def seeder?
    left.zero?
  end

  def leecher?
    left > 0
  end
end
