class CreateTorrents < ActiveRecord::Migration[8.1]
  def change
    create_table :torrents, id: :uuid do |t|
      t.string :info_hash, null: false
      t.string :name, null: false
      t.bigint :size, null: false
      t.integer :piece_length
      t.integer :num_pieces
      t.jsonb :files, default: []
      t.text :description
      t.string :category
      t.boolean :private, default: false
      t.string :created_by
      t.text :announce_urls
      t.integer :seeders, default: 0
      t.integer :leechers, default: 0
      t.integer :completed, default: 0
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
    
    add_index :torrents, :info_hash, unique: true
    add_index :torrents, :category
    add_index :torrents, :created_at
  end
end
