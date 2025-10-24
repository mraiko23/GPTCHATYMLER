class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat
  before_action :set_message, only: [:update, :regenerate]

  def create
    @message = @chat.messages.build(message_params)
    @message.role = 'user'
    
    if @message.save
      # Trigger AI response via ActionCable
      ChatResponseJob.perform_later(@chat.id, @message.id)
      
      # Update chat's updated_at to show it as recent
      @chat.touch
      
      # Rails will automatically render create.turbo_stream.erb
      # This prevents page reload and maintains WebSocket connection
    else
      @messages = @chat.messages.ordered.includes(:chat)
      @new_message = @message
      render 'chats/show', status: :unprocessable_entity
    end
  end

  def update
    # Only allow updating user messages
    unless @message.role == 'user'
      redirect_to @chat, alert: 'Можно редактировать только свои сообщения'
      return
    end

    if @message.update(message_params)
      # Regenerate AI response after user message update
      ChatResponseJob.perform_later(@chat.id, @message.id)
      
      # Update chat's updated_at
      @chat.touch
      
      redirect_to @chat, notice: 'Сообщение обновлено'
    else
      redirect_to @chat, alert: 'Ошибка при обновлении сообщения'
    end
  end

  def regenerate
    # Only allow regenerating assistant messages
    unless @message.role == 'assistant'
      redirect_to @chat, alert: 'Можно перегенерировать только ответы ассистента'
      return
    end

    # Save message created_at before deletion
    message_created_at = @message.created_at

    # Find the user message that prompted this response
    user_message = @chat.messages
                       .where(role: 'user')
                       .where('created_at <= ?', message_created_at)
                       .order(created_at: :desc)
                       .first

    if user_message
      # Get IDs of messages to delete for Turbo Stream
      @deleted_message_ids = @chat.messages
                                  .where('created_at >= ?', message_created_at)
                                  .pluck(:id)
      
      # Delete the current assistant message and any messages after it
      @chat.messages.where('created_at >= ?', message_created_at).destroy_all
      
      # Regenerate response
      ChatResponseJob.perform_later(@chat.id, user_message.id)
      
      # Update chat's updated_at
      @chat.touch
      
      # Rails will automatically render regenerate.turbo_stream.erb
    else
      redirect_to @chat, alert: 'Не удалось найти исходное сообщение для регенерации'
    end
  end

  private
  
  def set_chat
    @chat = current_user.chats.find(params[:chat_id])
  end

  def set_message
    @message = @chat.messages.find(params[:id])
  end
  
  def message_params
    params.require(:message).permit(:content, files: [])
  end
end
