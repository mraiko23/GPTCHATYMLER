require 'cgi'

class User < ApplicationRecord
  MIN_PASSWORD = 4
  GENERATED_EMAIL_SUFFIX = "@generated-mail.clacky.ai"

  has_secure_password validations: false

  generates_token_for :email_verification, expires_in: 2.days do
    email
  end
  generates_token_for :password_reset, expires_in: 20.minutes

  has_many :sessions, dependent: :destroy
  has_many :chats, dependent: :destroy
  has_many :messages, through: :chats

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :password, allow_nil: true, length: { minimum: MIN_PASSWORD }, if: :password_required?
  validates :password, confirmation: true, if: :password_required?

  normalizes :email, with: -> { _1.strip.downcase }

  before_validation if: :email_changed?, on: :update do
    self.verified = false
  end

  after_update if: :password_digest_previously_changed? do
    sessions.where.not(id: Current.session).delete_all
  end

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

  private

  def password_required?
    return false if oauth_user?
    password_digest.blank? || password.present?
  end

end
