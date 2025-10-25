class ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat, only: [:show, :edit, :update, :destroy]

  def index
    @chats = current_user.chats
    @chats = @chats.sort_by { |c| c.updated_at || c.created_at }.reverse
  end

  def show
    @messages = @chat.messages.sort_by { |m| [m.created_at, m.id] }
    @new_message = Message.new(chat_id: @chat.id)
  end

  def new
    @chat = Chat.new(user_id: current_user.id)
  end

  def create
    @chat = Chat.new(chat_params.merge(user_id: current_user.id))
    
    if @chat.save
      redirect_to @chat
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end
  
  def update
    if @chat.update(chat_params)
      redirect_to @chat, notice: 'Чат обновлен'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @chat.destroy
    redirect_to chats_path, notice: 'Чат удален'
  end

  private
  
  def set_chat
    @chat = current_user.chats.find { |c| c.id == params[:id].to_i }
    raise ActiveRecord::RecordNotFound unless @chat
  end
  
  def chat_params
    params.require(:chat).permit(:title)
  end
end
