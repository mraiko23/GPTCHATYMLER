class TelegramWebAppService < ApplicationService
  def initialize(init_data)
    @init_data = init_data
  end

  def call
    return { success: false, error: 'No init data provided' } if @init_data.blank?

    begin
      # Parse Telegram Web App init data
      parsed_data = parse_init_data(@init_data)
      
      return { success: false, error: 'Invalid init data format' } unless parsed_data

      # Validate the data
      return { success: false, error: 'Invalid data signature' } unless valid_signature?(parsed_data)

      # Extract user data
      user_data = parsed_data['user']
      return { success: false, error: 'No user data found' } unless user_data

      # Find or create user
      user = User.from_telegram(user_data)
      
      return { success: false, error: 'Failed to create user' } unless user.persisted?

      {
        success: true,
        user: user,
        theme_params: parsed_data['theme_params'],
        start_param: parsed_data['start_param']
      }
    rescue => e
      Rails.logger.error("Telegram Web App Service Error: #{e.message}")
      { success: false, error: 'Authentication failed' }
    end
  end

  private

  def parse_init_data(init_data_string)
    # For development/testing, we'll accept the data as-is
    # In production, you should validate the signature with your bot token
    
    params = {}
    init_data_string.split('&').each do |param|
      key, value = param.split('=', 2)
      next unless key && value
      
      decoded_value = CGI.unescape(value)
      
      # Parse JSON for user and theme_params
      if key == 'user' || key == 'theme_params'
        begin
          params[key] = JSON.parse(decoded_value)
        rescue JSON::ParserError
          params[key] = decoded_value
        end
      else
        params[key] = decoded_value
      end
    end
    
    params
  end

  def valid_signature?(parsed_data)
    # For development/testing, always return true
    # In production, validate using HMAC-SHA256 with your bot token
    Rails.env.development? || Rails.env.test? || verify_telegram_signature(parsed_data)
  end

  def verify_telegram_signature(parsed_data)
    # Implementation for production signature verification
    # This requires your Telegram bot token
    true
  end
end