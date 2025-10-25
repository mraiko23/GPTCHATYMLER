class Session < ApplicationRecord
  attribute :user_id, :integer
  attribute :user_agent, :string
  attribute :ip_address, :string
  
  belongs_to :user

  before_create :set_request_info
  
  private
  
  def set_request_info
    self.user_agent = Current.user_agent
    self.ip_address = Current.ip_address
  end
end
