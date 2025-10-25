class StorageController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:show]
  
  def show
    key = params[:key]
    file_path = Rails.root.join('storage', key)
    
    if File.exist?(file_path)
      send_file file_path, disposition: 'inline'
    else
      head :not_found
    end
  end
end
