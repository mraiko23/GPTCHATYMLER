class ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat, only: [:show, :edit, :update, :destroy]

  def index
    @chats = current_user.chats.recent.includes(:messages)
  end

  def show
    @messages = @chat.messages.ordered.includes(:chat)
    @new_message = @chat.messages.build
  end

  def new
    @chat = current_user.chats.build
  end

  def create
    @chat = current_user.chats.build(chat_params)
    
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
    @chat = current_user.chats.find(params[:id])
  end
  
  def chat_params
    params.require(:chat).permit(:title)
  end
end
