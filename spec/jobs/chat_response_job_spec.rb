require 'rails_helper'

RSpec.describe ChatResponseJob, type: :job do
  let(:user) { create(:user) }
  let(:chat) { create(:chat, user: user) }
  let(:message) { create(:message, chat: chat, role: 'user', content: 'Hello AI') }
  
  describe '#perform' do
    it 'executes successfully' do
      expect {
        ChatResponseJob.perform_now(chat.id, message.id)
      }.not_to raise_error
    end
  end
end
