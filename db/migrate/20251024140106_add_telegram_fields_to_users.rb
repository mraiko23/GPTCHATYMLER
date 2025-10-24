class AddTelegramFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :telegram_id, :bigint
    add_column :users, :username, :string
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :photo_url, :string

    add_index :users, :telegram_id
  end
end
