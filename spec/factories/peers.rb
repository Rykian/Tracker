FactoryBot.define do
  factory :peer do
    association :torrent
    association :user
    peer_id { SecureRandom.hex(10) } # 20 character hex string
    ip { Faker::Internet.ip_v4_address }
    port { rand(1024..65535) }
    uploaded { rand(0..1_000_000_000) }
    downloaded { rand(0..1_000_000_000) }
    left { rand(0..10_000_000_000) }
    event { %w[started completed stopped].sample }
    last_announce { Time.current }

    trait :seeder do
      left { 0 }
      event { 'completed' }
    end

    trait :leecher do
      left { rand(1..10_000_000_000) }
      event { 'started' }
    end

    trait :stale do
      last_announce { 2.hours.ago }
    end
  end
end
