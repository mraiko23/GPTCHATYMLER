class Chat < ApplicationRecord
  attribute :user_id, :integer
  attribute :title, :string
  
  belongs_to :user
  has_many :messages, dependent: :destroy
  
  validates :title, presence: true
  
  before_validation :set_default_title, if: -> { new_record? }
  
  def self.recent
    all.sort_by { |c| c.updated_at || c.created_at }.reverse
  end
  
  def last_message
    messages.sort_by { |m| [m.created_at, m.id] }.last
  end
  
  def message_count
    messages.count
  end
  
  def messages
    Message.where(chat_id: id).sort_by { |m| [m.created_at, m.id] }
  end
  
  private
  
  def set_default_title
    self.title ||= "Новый чат #{Time.current.strftime('%d.%m.%Y %H:%M')}"
  end
end
