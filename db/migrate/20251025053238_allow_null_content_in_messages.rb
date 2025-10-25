class AllowNullContentInMessages < ActiveRecord::Migration[7.2]
  def change
    # Allow null content so users can send files without text
    change_column_null :messages, :content, true
    
    # Set empty string for existing null content (if any)
    Message.where(content: nil).update_all(content: '')
  end
end
