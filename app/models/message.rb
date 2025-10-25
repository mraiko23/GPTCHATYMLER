class Message < ApplicationRecord
  include LlmMessageValidationConcern
  
  belongs_to :chat
  has_one :user, through: :chat
  
  # File attachments using ActiveStorage
  has_many_attached :files
  
  # Validations are handled by LlmMessageValidationConcern for role and content
  
  # Custom validation: user messages must have either content or files
  validate :content_or_files_present, on: :create, if: :user?
  
  # Attachments are stored as JSON
  # Format: [{ "url": "https://...", "type": "image", "name": "file.jpg" }]
  
  scope :ordered, -> { order(created_at: :asc) }
  scope :by_role, ->(role) { where(role: role) }
  
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
