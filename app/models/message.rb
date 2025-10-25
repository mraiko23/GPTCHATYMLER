class Message < ApplicationRecord
  include LlmMessageValidationConcern
  
  attribute :chat_id, :integer
  attribute :role, :string
  attribute :content, :string
  attribute :attachments, :string  # JSON string
  
  belongs_to :chat
  
  # File attachments using JSON storage
  has_many_attached :files
  
  # Custom validation: user messages must have either content or files
  # Note: We skip this on new_record since files are attached after save
  validate :content_or_files_present, if: -> { user? && !new_record? }
  
  def self.ordered
    all.sort_by { |m| [m.created_at, m.id] }
  end
  
  def self.by_role(role)
    where(role: role)
  end
  
  def user
    chat&.user
  end
  
  def user_message?
    role == 'user'
  end
  
  def assistant_message?
    role == 'assistant'
  end
  
  private
  
  def content_or_files_present
    if content.blank? && !files.attached?
      errors.add(:base, 'Message must have either text content or attached files')
    end
  end
end
