class Torrent < ApplicationRecord
  belongs_to :user
  has_many :peers, dependent: :destroy

  validates :info_hash, presence: true, uniqueness: true, length: { is: 40 }
  validates :name, presence: true
  validates :size, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :seeders, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :leechers, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :completed, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def magnet_link
    trackers = announce_urls&.split("\n")&.map { |url| "&tr=#{ERB::Util.url_encode(url)}" }&.join || ""
    "magnet:?xt=urn:btih:#{info_hash}&dn=#{ERB::Util.url_encode(name)}#{trackers}"
  end
end
