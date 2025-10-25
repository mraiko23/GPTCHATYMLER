class ChatResponseJob < ApplicationJob
  queue_as :default

  # Configure retry strategy
  # retry_on StandardError, wait: :exponentially_longer, attempts: 3
  # discard_on ActiveRecord::RecordNotFound

  # IMPORTANT: Do NOT catch exceptions and swallow them!
  # BAD:
  #   rescue => e
  #     Rails.logger.error(e)
  #     # Error is hidden, job appears successful
  #   end
  #
  # GOOD: Let exceptions propagate naturally
  #   rescue => e
  #     Rails.logger.error(e)
  #     raise  # Re-raise to trigger retry/failure handling
  #   end
  #
  # Why: Development uses inline mode for immediate feedback.
  #      Production has GoodJob dashboard to track failures.
  #
  # 💡 Always consider syncing results to frontend, use the following example code:
  #
  #   ActionCable.server.broadcast("xxx_#{id}", {
  #     type: 'update',  # REQUIRED: type field routes to client handler method
  #     data: your_data  # Frontend MUST implement xxxController#handleUpdate() method
  #   })
  def perform(chat_id, user_message_id)
    chat = Chat.find(chat_id)
    user_message = Message.find(user_message_id)
    
    # Get conversation history (last 20 messages for context)
    messages = chat.messages.ordered.last(20)
    conversation_history = messages.map { |msg| "#{msg.role}: #{msg.content}" }.join("\n")
    
    # Process attached files
    file_context = process_attached_files(user_message)
    
    
    # Check if the user wants to search the internet
    search_context = ""
    user_query = user_message.content.to_s.downcase
    needs_search = user_query.match?(/найди|поищи|найти|поиск|что происходит|новости|актуальн|последни/)
    
    if needs_search
      search_query = extract_search_query(user_message.content)
      if search_query.present?
        search_results = WebSearchService.new(query: search_query).call
        
        if search_results[:success]
          search_context = "\n\nАКТУАЛЬНАЯ ИНФОРМАЦИЯ ИЗ ИНТЕРНЕТА:\n#{search_results[:summary]}\n"
        else
          search_context = "\n\nОШИБКА ПОИСКА: #{search_results[:error]}\n"
        end
      end
    end
    
    # Get current date for context
    current_date = Time.current.strftime('%d.%m.%Y')
    current_time = Time.current.strftime('%H:%M')
    
    # Create system prompt for AI assistant
    system_prompt = <<~PROMPT
      You are a helpful AI assistant in a Telegram-style chat.
      
      ТЕКУЩАЯ ДАТА И ВРЕМЯ: #{current_date} #{current_time} (UTC+0)
      
      Your capabilities:
      1. Answer questions and provide information
      2. Help with various tasks
      3. Search the internet for CURRENT information#{search_context.present? ? ' - АКТУАЛЬНЫЕ ДАННЫЕ ИЗ ИНТЕРНЕТА ПОЛУЧЕНЫ И ПРИВЕДЕНЫ НИЖЕ' : ''}
      
      #{search_context.present? ? "⚠️ ВАЖНО: Используй ТОЛЬКО информацию из раздела 'АКТУАЛЬНАЯ ИНФОРМАЦИЯ ИЗ ИНТЕРНЕТА' для ответов на вопросы о текущих событиях, новостях или актуальных данных. НЕ используй устаревшую информацию из базы знаний.\n" : ''}
      Respond in Russian language. Be helpful, friendly, and conversational.#{search_context}
    PROMPT
    
    # Create AI response message
    ai_message = chat.messages.create!(
      role: 'assistant',
      content: '',  # Will be filled by streaming
    )
    
    # Broadcast that AI response is starting
    ActionCable.server.broadcast("chat_#{chat_id}", {
      type: 'response-start',
      message_id: ai_message.id
    })
    
    # Stream AI response via ActionCable
    full_response = ""
    
    # Build LLM options
    llm_options = { system: system_prompt }
    
    # Add images to LLM options if present
    if file_context[:images].present?
      llm_options[:images] = file_context[:images]
    end
    
    # Build full prompt with conversation history and file context
    user_content = user_message.content.to_s.strip
    
    # Handle file-only messages
    if user_content.blank? && file_context[:images].present?
      user_content = "Что на этом изображении?"
    elsif user_content.blank? && file_context[:text_content].present?
      user_content = "Проанализируй этот файл"
    end
    
    full_prompt = if conversation_history.present?
      "ИСТОРИЯ РАЗГОВОРА:\n#{conversation_history}\n\n#{file_context[:text_content]}ТЕКУЩИЙ ВОПРОС ПОЛЬЗОВАТЕЛЯ: #{user_content}"
    else
      "#{file_context[:text_content]}#{user_content}"
    end
    
    LlmService.call(
      prompt: full_prompt,
      **llm_options
    ) do |chunk|
      full_response += chunk
      
      # Broadcast chunk to frontend
      ActionCable.server.broadcast("chat_#{chat_id}", {
        type: 'chunk',
        message_id: ai_message.id,
        chunk: chunk
      })
    end
    
    # Update the message with the full response
    ai_message.update!(content: full_response)
    
    # Broadcast completion
    ActionCable.server.broadcast("chat_#{chat_id}", {
      type: 'complete',
      message_id: ai_message.id,
      content: full_response
    })
    
  rescue => e
    Rails.logger.error("ChatResponseJob failed: #{e.message}")
    
    # Broadcast error to frontend
    ActionCable.server.broadcast("chat_#{chat_id}", {
      type: 'error',
      message: 'Произошла ошибка при генерации ответа. Попробуйте еще раз.'
    })
    
    raise # Re-raise to trigger retry/failure handling
  end
  
  private
  
  def process_attached_files(message)
    result = { images: [], text_content: "" }
    
    return result unless message.files.attached?
    
    images = []
    text_parts = []
    
    message.files.each do |file|
      if file.content_type.start_with?('image/')
        # For images, convert to base64 data URL for vision models
        begin
          image_data = file.download
          base64_image = Base64.strict_encode64(image_data)
          data_url = "data:#{file.content_type};base64,#{base64_image}"
          images << data_url
        rescue => e
          Rails.logger.error("Failed to process image #{file.filename}: #{e.message}")
        end
      elsif file.content_type.start_with?('text/') || file.content_type == 'application/json'
        # For text files, read and include content
        begin
          text_content = file.download.force_encoding('UTF-8')
          text_parts << "\n\nПРИКРЕПЛЕННЫЙ ФАЙЛ: #{file.filename}\n```\n#{text_content}\n```\n"
        rescue => e
          Rails.logger.error("Failed to process text file #{file.filename}: #{e.message}")
        end
      end
    end
    
    result[:images] = images if images.any?
    result[:text_content] = text_parts.join if text_parts.any?
    
    result
  end
  
  def extract_search_query(content)
    # Remove common search triggers and extract the actual query
    query = content.to_s.strip
    
    # Remove common Russian search triggers
    query = query.gsub(/^(найди|поищи|найти|поиск|что происходит|последние новости)\s*/i, '')
    
    # Remove common prepositions and conjunctions
    query = query.gsub(/^(про|о|об|с|со|в|на|за|по)\s+/i, '')
    
    # Clean up and return
    query.strip.presence
  end
  

end
