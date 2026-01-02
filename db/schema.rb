# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_02_100518) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "peers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "downloaded", default: 0
    t.string "event"
    t.string "ip", null: false
    t.datetime "last_announce", null: false
    t.bigint "left", null: false
    t.string "peer_id", null: false
    t.integer "port", null: false
    t.uuid "torrent_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "uploaded", default: 0
    t.uuid "user_id", null: false
    t.index ["last_announce"], name: "index_peers_on_last_announce"
    t.index ["torrent_id", "left"], name: "index_peers_on_torrent_id_and_left"
    t.index ["torrent_id", "peer_id", "ip", "port"], name: "index_peers_on_torrent_peer_ip_port", unique: true
    t.index ["torrent_id"], name: "index_peers_on_torrent_id"
    t.index ["user_id"], name: "index_peers_on_user_id"
  end

  create_table "torrents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "announce_urls"
    t.integer "category_id"
    t.integer "completed", default: 0
    t.datetime "created_at", null: false
    t.string "created_by"
    t.text "description"
    t.jsonb "files", default: []
    t.string "info_hash", null: false
    t.integer "leechers", default: 0
    t.string "name", null: false
    t.integer "num_pieces"
    t.integer "piece_length"
    t.boolean "private", default: false
    t.integer "seeders", default: 0
    t.bigint "size", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["category_id"], name: "index_torrents_on_category_id"
    t.index ["created_at"], name: "index_torrents_on_created_at"
    t.index ["info_hash"], name: "index_torrents_on_info_hash", unique: true
    t.index ["user_id"], name: "index_torrents_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "downloaded", default: 0, null: false
    t.string "email"
    t.string "password_digest"
    t.datetime "updated_at", null: false
    t.bigint "uploaded", default: 0, null: false
  end

  add_foreign_key "peers", "torrents"
  add_foreign_key "peers", "users"
  add_foreign_key "torrents", "users"
end
