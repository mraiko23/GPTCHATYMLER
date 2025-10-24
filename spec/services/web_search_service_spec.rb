require 'rails_helper'

RSpec.describe WebSearchService, type: :service do
  describe '#call' do
    it 'can be initialized and called' do
      service = WebSearchService.new(query: 'test query')
      expect { service.call }.not_to raise_error
    end
  end
end
