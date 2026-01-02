FactoryBot.define do
  factory :torrent do
    association :user
    info_hash { SecureRandom.hex(20) } # 40 character hex string
    name { Faker::App.name }
    size { rand(1_000_000..10_000_000_000) }
    piece_length { [262144, 524288, 1048576, 2097152].sample }
    num_pieces { (size.to_f / piece_length).ceil }
    files { [{ "path" => Faker::File.file_name, "length" => size }] }
    description { Faker::Lorem.paragraph }
    category_id { Category.ids.sample }
    private { false }
    created_by { Faker::Internet.username }
    announce_urls { "http://tracker.example.com:8080/announce\nudp://tracker.example.org:6969/announce" }
    seeders { rand(0..100) }
    leechers { rand(0..50) }
    completed { rand(0..1000) }
  end
end
