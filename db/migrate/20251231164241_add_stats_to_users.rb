class AddStatsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :uploaded, :bigint, default: 0, null: false
    add_column :users, :downloaded, :bigint, default: 0, null: false
  end
end
