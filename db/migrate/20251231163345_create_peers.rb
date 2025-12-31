class CreatePeers < ActiveRecord::Migration[8.1]
  def change
    create_table :peers, id: :uuid do |t|
      t.references :torrent, null: false, foreign_key: true, type: :uuid
      t.string :peer_id, null: false
      t.string :ip, null: false
      t.integer :port, null: false
      t.bigint :uploaded, default: 0
      t.bigint :downloaded, default: 0
      t.bigint :left, null: false
      t.string :event
      t.datetime :last_announce, null: false

      t.timestamps
    end
    
    add_index :peers, [:torrent_id, :peer_id, :ip, :port], unique: true, name: 'index_peers_on_torrent_peer_ip_port'
    add_index :peers, :last_announce
    add_index :peers, [:torrent_id, :left]
  end
end
