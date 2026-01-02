class RenameCategoryToCategoryIdInTorrents < ActiveRecord::Migration[8.1]
  # Minimal model to avoid callbacks/validations during migration
  class MigrationTorrent < ActiveRecord::Base
    self.table_name = "torrents"
  end

  OTHER_CATEGORY_ID = 8000

  def up
    migrate_category_names_to_ids
    rename_column :torrents, :category, :category_id
    change_column :torrents, :category_id, :integer, using: "category_id::integer"
  end

  def down
    change_column :torrents, :category_id, :string
    revert_category_ids_to_names
    rename_column :torrents, :category_id, :category
  end

  private

  def migrate_category_names_to_ids
    mapping = Category.all.invert

    say_with_time "Converting category names to Torznab IDs" do
      MigrationTorrent.where.not(category: nil).find_each(batch_size: 100) do |torrent|
        name = torrent[:category]
        id = mapping[name] || OTHER_CATEGORY_ID
        torrent.update_columns(category: id)
      end

      MigrationTorrent.where(category: nil).update_all(category: OTHER_CATEGORY_ID)
    end
  end

  def revert_category_ids_to_names
    say_with_time "Reverting Torznab IDs to category names" do
      MigrationTorrent.find_each(batch_size: 100) do |torrent|
        id = torrent[:category_id].to_i
        name = Category.name_for(id) || Category.name_for(OTHER_CATEGORY_ID)
        torrent.update_columns(category_id: name)
      end
    end
  end
end
