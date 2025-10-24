require 'rails_helper'

RSpec.describe TelegramWebAppService, type: :service do
  describe '#call' do
    it 'can be initialized with init_data and called' do
      # Mock Telegram init data
      init_data = "user=%7B%22id%22%3A123456789%2C%22first_name%22%3A%22Test%22%2C%22username%22%3A%22testuser%22%7D&auth_date=1234567890&hash=test_hash"
      service = TelegramWebAppService.new(init_data)
      result = service.call
      expect(result).to be_a(Hash)
      expect(result).to have_key(:success)
    end
    
    it 'handles empty init_data' do
      service = TelegramWebAppService.new("")
      result = service.call
      expect(result[:success]).to be_falsey
    end
  end
end
