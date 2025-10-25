require 'cgi'

class User < ApplicationRecord
  MIN_PASSWORD = 4
  GENERATED_EMAIL_SUFFIX = "@generated-mail.clacky.ai"

  # Attributes
  attribute :name, :string
  attribute :email, :string
  attribute :password_digest, :string
  attribute :verified, :boolean, default: false
  attribute :provider, :string
  attribute :uid, :string
  attribute :telegram_id, :integer
  attribute :username, :string
  attribute :first_name, :string
  attribute :last_name, :string
  attribute :photo_url, :string
  
  attr_accessor :password, :password_confirmation

  # Associations
  has_many :sessions, dependent: :destroy
  has_many :chats, dependent: :destroy

  # Validations
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :email_uniqueness
  validates :password, allow_nil: true, length: { minimum: MIN_PASSWORD }, if: :password_required?
  validates :password, confirmation: true, if: :password_required?
  
  # Callbacks
  before_validation :normalize_email
  before_validation :set_verified_false_if_email_changed, if: -> { !new_record? }
  before_save :encrypt_password, if: -> { password.present? }
  after_save :delete_other_sessions_if_password_changed, if: -> { !new_record? }

  # Telegram authentication methods
  def self.from_telegram(telegram_data)
    telegram_id = telegram_data['id']
    username = telegram_data['username']
    first_name = telegram_data['first_name']
    last_name = telegram_data['last_name']
    photo_url = telegram_data['photo_url']
    
    # Find or create user by telegram_id
    user = find_by(telegram_id: telegram_id)
    
    if user
      # Update existing user with latest data
      user.update(
        username: username,
        first_name: first_name,
        last_name: last_name,
        photo_url: photo_url,
        verified: true  # Telegram users are pre-verified
      )
    else
      # Create new user
      email = generate_email_from_telegram(username, telegram_id)
      user = create(
        telegram_id: telegram_id,
        username: username,
        first_name: first_name,
        last_name: last_name,
        photo_url: photo_url,
        name: [first_name, last_name].compact.join(' ').presence || username || "User#{telegram_id}",
        email: email,
        verified: true
      )
    end
    
    user
  end
  
  def self.generate_email_from_telegram(username, telegram_id)
    if username.present?
      "#{username.downcase}#{GENERATED_EMAIL_SUFFIX}"
    else
      "telegram_#{telegram_id}#{GENERATED_EMAIL_SUFFIX}"
    end
  end
  
  def telegram_user?
    telegram_id.present?
  end
  
  def display_name
    if telegram_user?
      [first_name, last_name].compact.join(' ').presence || username || "User#{telegram_id}"
    else
      name
    end
  end

  # OAuth methods
  def self.from_omniauth(auth)
    name = auth.info.name.presence || "#{SecureRandom.hex(10)}_user"
    email = auth.info.email.presence || User.generate_email(name)

    # First, try to find user by email
    user = find_by(email: email)
    if user
      user.update(provider: auth.provider, uid: auth.uid)
      return user
    end

    # Then, try to find user by provider and uid
    user = find_by(provider: auth.provider, uid: auth.uid)
    return user if user

    # If not found, create a new user
    verified = !email.end_with?(GENERATED_EMAIL_SUFFIX)
    create(
      name: name,
      email: email,
      provider: auth.provider,
      uid: auth.uid,
      verified: verified,
    )
  end

  def self.generate_email(name)
    if name.present?
      name.downcase.gsub(' ', '_') + GENERATED_EMAIL_SUFFIX
    else
      SecureRandom.hex(10) + GENERATED_EMAIL_SUFFIX
    end
  end

  def oauth_user?
    provider.present? && uid.present?
  end

  def email_was_generated?
    email.end_with?(GENERATED_EMAIL_SUFFIX)
  end
  
  def avatar_url
    photo_url.presence || "https://ui-avatars.com/api/?name=#{CGI.escape(display_name)}&background=0088cc&color=fff"
  end
  
  def verified?
    verified == true
  end
  
  # Password authentication
  def authenticate(password)
    return false unless password_digest.present?
    BCrypt::Password.new(password_digest).is_password?(password) ? self : false
  end
  
  # Token generation (simplified)
  def self.generate_token_for(purpose)
    # This is simplified - just return a random token
    SecureRandom.urlsafe_base64(32)
  end
  
  def generates_token_for(purpose, expires_in: nil, &block)
    SecureRandom.urlsafe_base64(32)
  end

  private
  
  def email_uniqueness
    existing = User.find_by(email: email)
    if existing && existing.id != id
      errors.add(:email, 'has already been taken')
    end
  end

  def password_required?
    return false if oauth_user?
    password_digest.blank? || password.present?
  end
  
  def normalize_email
    self.email = email.strip.downcase if email.present?
  end
  
  def set_verified_false_if_email_changed
    if email_changed?
      self.verified = false
    end
  end
  
  def email_changed?
    # Simple implementation - check if email is different from stored value
    return false if new_record?
    
    stored = self.class.find_by(id: id)
    stored && stored.email != email
  end
  
  def delete_other_sessions_if_password_changed
    # Check if password_digest changed
    stored = self.class.find_by(id: id)
    if stored && stored.password_digest != password_digest
      # Delete all sessions except current
      sessions.each do |session|
        session.destroy unless session.id == Current.session&.id
      end
    end
  end
  
  def encrypt_password
    require 'bcrypt'
    self.password_digest = BCrypt::Password.create(password)
  end
end
