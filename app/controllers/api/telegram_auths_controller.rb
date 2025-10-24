class Api::TelegramAuthsController < ApplicationController
  skip_before_action :authenticate, only: [:create]
  
  def create
    init_data = params[:init_data]
    
    return render json: { success: false, error: 'No init data provided' }, status: :bad_request if init_data.blank?

    result = TelegramWebAppService.new(init_data).call
    
    if result[:success]
      user = result[:user]
      
      # Create session for the user
      session = user.sessions.create!
      cookies.signed.permanent[:session_token] = { value: session.id, httponly: true }
      
      render json: { 
        success: true, 
        user: {
          id: user.id,
          name: user.display_name,
          avatar_url: user.avatar_url,
          first_name: user.first_name,
          last_name: user.last_name,
          username: user.username
        },
        redirect_url: chats_path
      }
    else
      render json: { success: false, error: result[:error] }, status: :unauthorized
    end
  end

  private
  
  def telegram_auth_params
    params.permit(:init_data)
  end
end