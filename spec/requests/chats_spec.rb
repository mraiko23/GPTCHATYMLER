require 'rails_helper'

RSpec.describe "Chats", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }

  describe "GET /chats" do
    it "returns http success" do
      get chats_path
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "GET /chats/:id" do
    let(:chat) { create(:chat, user: user) }


    it "returns http success" do
      get chat_path(chat)
      expect(response).to be_success_with_view_check('show')
    end
  end

  describe "GET /chats/new" do
    it "returns http success" do
      get new_chat_path
      expect(response).to be_success_with_view_check('new')
    end
  end
  
end
