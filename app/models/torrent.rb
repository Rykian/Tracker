# Torrent model - Torrent metadata with category and statistics
#
# Represents a tracked torrent with real-time peer statistics and categorization.
# Statistics are updated by UpdateTorrentStatsJob after peer announces and count
# only active peers (announced within last hour).
#
class Torrent < ApplicationRecord
  belongs_to :user
  has_many :peers, dependent: :destroy

  validates :info_hash, presence: true, uniqueness: true, length: { is: 40 }
  validates :name, presence: true
  validates :size, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :seeders, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :leechers, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :completed, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :category_id, inclusion: { in: Category.ids, message: "must be a valid Torznab category ID" }, allow_nil: true

  # Generates magnet URI for this torrent
  #
  # Constructs a magnet link containing:
  #   - info hash (xt=urn:btih:...)
  #   - display name (dn=...)
  #   - tracker announce URLs (tr=...)
  #
  # @return [String] Magnet URI
  # @example
  #   torrent.magnet_link
  #   # => "magnet:?xt=urn:btih:abcd1234...&dn=My+Torrent&tr=http://tracker.example.com/announce"
  def magnet_link
    trackers = announce_urls&.split("\n")&.map { |url| "&tr=#{ERB::Util.url_encode(url)}" }&.join || ""
    "magnet:?xt=urn:btih:#{info_hash}&dn=#{ERB::Util.url_encode(name)}#{trackers}"
  end

  # Returns the human-readable category name for this torrent
  #
  # @return [String, nil] Category name if category_id is set, nil otherwise
  # @example
  #   torrent.category_id = 2040
  #   torrent.category_name # => "Movies/HD"
  def category_name
    return nil unless category_id.present?
    Category.name_for(category_id)
  end
end
