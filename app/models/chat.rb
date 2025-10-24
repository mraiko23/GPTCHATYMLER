class Chat < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy
  
  validates :title, presence: true
  
  scope :recent, -> { order(updated_at: :desc) }
  
  before_validation :set_default_title, on: :create
  
  def last_message
    messages.ordered.last
  end
  
  def message_count
    messages.count
  end
  
  private
  
  def set_default_title
    self.title ||= "Новый чат #{Time.current.strftime('%d.%m.%Y %H:%M')}"
  end
end
