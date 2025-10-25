class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat
  before_action :set_message, only: [:update, :regenerate]

  def create
    # Separate files from other params
    files_param = message_params[:files]
    params_hash = message_params.to_h.except('files')
    
    # Validate that either content or files are present
    if params_hash[:content].blank? && (files_param.blank? || files_param.reject(&:blank?).empty?)
      @messages = @chat.messages.sort_by { |m| [m.created_at, m.id] }
      @new_message = Message.new(params_hash.merge(chat_id: @chat.id, role: 'user'))
      @new_message.errors.add(:base, 'Message must have either text content or attached files')
      render 'chats/show', status: :unprocessable_entity
      return
    end
    
    @message = Message.new(params_hash.merge(chat_id: @chat.id, role: 'user'))
    
    # Save message first to get ID
    if @message.save
      # Attach files AFTER save so message has ID
      if files_param.present?
        files_param.each do |file|
          @message.files.attach(file) if file.present?
        end
      end
      
      # Trigger AI response via ActionCable
      ChatResponseJob.perform_later(@chat.id, @message.id)
      
      # Update chat's updated_at to show it as recent
      @chat.update(updated_at: Time.current)
      
      # Rails will automatically render create.turbo_stream.erb
      # This prevents page reload and maintains WebSocket connection
    else
      @messages = @chat.messages.sort_by { |m| [m.created_at, m.id] }
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

    # Separate files from other params
    files_param = message_params[:files]
    params_hash = message_params.to_h.except('files')
    
    if @message.update(params_hash)
      # Attach new files AFTER update
      if files_param.present?
        files_param.each do |file|
          @message.files.attach(file) if file.present?
        end
      end
      
      # Regenerate AI response after user message update
      ChatResponseJob.perform_later(@chat.id, @message.id)
      
      # Update chat's updated_at
      @chat.update(updated_at: Time.current)
      
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

    # Save message id before deletion
    message_id = @message.id

    # Find the user message that prompted this response
    # We need to find the last user message that comes BEFORE this assistant message
    all_messages = @chat.messages.sort_by { |m| [m.created_at, m.id] }
    message_index = all_messages.index { |m| m.id == message_id }
    
    # Find the previous user message
    user_message = nil
    if message_index && message_index > 0
      (message_index - 1).downto(0) do |i|
        if all_messages[i].role == 'user'
          user_message = all_messages[i]
          break
        end
      end
    end

    if user_message
      # Save user message ID before any deletions
      user_message_id = user_message.id
      
      # Verify user message still exists and wasn't deleted by concurrent regeneration
      unless Message.where(id: user_message_id).any?
        redirect_to @chat, alert: 'Исходное сообщение было удалено'
        return
      end
      
      # Get messages to delete: current assistant message and everything after it
      # But keep the user message!
      messages_to_delete = all_messages.select do |m|
        m_index = all_messages.index { |msg| msg.id == m.id }
        m_index && m_index >= message_index
      end
      
      # Get IDs for Turbo Stream
      @deleted_message_ids = messages_to_delete.map(&:id)
      
      # Delete the messages
      messages_to_delete.each(&:destroy)
      
      # Verify message was actually deleted (not already in progress)
      if Message.where(id: message_id).any?
        redirect_to @chat, alert: 'Не удалось удалить сообщение для регенерации'
        return
      end
      
      # Regenerate response using saved ID
      ChatResponseJob.perform_later(@chat.id, user_message_id)
      
      # Update chat's updated_at
      @chat.update(updated_at: Time.current)
      
      # Rails will automatically render regenerate.turbo_stream.erb
    else
      redirect_to @chat, alert: 'Не удалось найти исходное сообщение для регенерации'
    end
  end

  private
  
  def set_chat
    @chat = current_user.chats.find { |c| c.id == params[:chat_id].to_i }
    raise ActiveRecord::RecordNotFound unless @chat
  end

  def set_message
    @message = @chat.messages.find { |m| m.id == params[:id].to_i }
    raise ActiveRecord::RecordNotFound unless @message
  end
  
  def message_params
    params.require(:message).permit(:content, files: [])
  end
end
