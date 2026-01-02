class User < ApplicationRecord
  has_secure_password
  has_many :torrents, dependent: :destroy
  has_many :peers, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }

  def ratio
    return nil if uploaded.zero? && downloaded.zero?
    return Float::INFINITY if downloaded.zero? && uploaded.positive?
    return 0.0 if uploaded.zero?

    (uploaded.to_f / downloaded).round(2)
  end

  def update_stats!(uploaded_delta, downloaded_delta)
    increment!(:uploaded, uploaded_delta)
    increment!(:downloaded, downloaded_delta)
  end
end
