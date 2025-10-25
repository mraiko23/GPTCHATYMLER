class SessionsController < ApplicationController
  before_action :authenticate_user!, only: [:show, :devices, :destroy_one]

  def show
    @session = Current.session
    @user = current_user
  end

  def devices
    @sessions = Session.where(user_id: current_user.id).sort_by(&:created_at).reverse
  end

  def new
    @user = User.new
  end

  def create
    if user = User.authenticate_by(email: params[:user][:email], password: params[:user][:password])
      @session = Session.create!(user_id: user.id)
      cookies.signed.permanent[:session_token] = { value: @session.id, httponly: true }
      redirect_to root_path, notice: "Signed in successfully"
    else
      redirect_to sign_in_path(email_hint: params[:user][:email]), alert: "That email or password is incorrect"
    end
  end


  def destroy
    @session = Current.session
    @session.destroy if @session
    cookies.delete(:session_token)
    redirect_to root_path, notice: "Signed out successfully"
  end

  def destroy_one
    @session = Session.find_by(id: params[:id])
    return redirect_to(devices_session_path, alert: "Session not found") unless @session
    return redirect_to(devices_session_path, alert: "Unauthorized") unless @session.user_id == current_user.id
    @session.destroy
    redirect_to(devices_session_path, notice: "That session has been logged out")
  end
end
