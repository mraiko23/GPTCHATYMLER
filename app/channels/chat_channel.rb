class ChatChannel < ApplicationCable::Channel
  def subscribed
    chat_id = params[:chat_id]
    
    # Verify user has access to this chat
    chat = Chat.find(chat_id)
    reject unless chat && chat.user_id == current_user.id
    
    # Stream from the specific chat channel
    stream_from "chat_#{chat_id}"
  rescue StandardError => e
    handle_channel_error(e)
    reject
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  rescue StandardError => e
    handle_channel_error(e)
  end

  # Handle sending user messages and triggering AI responses
  def send_message(data)
    chat_id = params[:chat_id]
    chat = Chat.find(chat_id)
    return unless chat && chat.user_id == current_user.id
    
    # Create user message
    user_message = Message.create!(
      chat_id: chat.id,
      role: 'user',
      content: data['content'] || ''
    )
    
    # Handle file attachments if provided
    if data['files'].present?
      data['files'].each do |file_data|
        # File upload would be handled via regular form submission
        # This is a placeholder for future file processing
      end
    end
    
    # Broadcast the user message immediately
    ActionCable.server.broadcast(
      "chat_#{chat_id}",
      {
        type: 'new-message',
        id: user_message.id,
        chat_id: chat_id,
        role: 'user',
        content: user_message.content,
        created_at: user_message.created_at.iso8601,
        has_files: user_message.files.attached?
      }
    )
    
    # Start AI response job
    ChatResponseJob.perform_later(chat_id, user_message.id)
  rescue StandardError => e
    handle_channel_error(e)
  end
  
  # Send typing indicator
  def typing_indicator(data)
    chat_id = params[:chat_id]
    
    ActionCable.server.broadcast(
      "chat_#{chat_id}",
      {
        type: 'typing-indicator',
        user_id: current_user.id,
        username: current_user.username || current_user.first_name,
        typing: data['typing']
      }
    )
  rescue StandardError => e
    handle_channel_error(e)
  end
  private

  def current_user
    @current_user ||= connection.current_user
  end
end
