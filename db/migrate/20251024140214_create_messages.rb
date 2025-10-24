class CreateMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :messages do |t|
      t.references :chat
      t.string :role, null: false
      t.text :content, null: false
      t.jsonb :attachments


      t.timestamps
    end
  end
end
