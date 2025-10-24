module AuthenticationHelpers
  def sign_in_as(user)
    # Telegram-only authentication: Create session directly
    @auth_session = user.sessions.create!
    # Set Current.session for immediate use
    Current.session = @auth_session
  end
  
  # Override request method to add Authorization header
  [:get, :post, :put, :patch, :delete].each do |method|
    define_method(method) do |path, **args|
      if @auth_session
        args[:headers] ||= {}
        args[:headers]['Authorization'] = "Bearer #{@auth_session.id}"
      end
      super(path, **args)
    end
  end

  def sign_in_system(user)
    # For system tests with Telegram-only auth: Create session directly
    session = user.sessions.create!
    # Use page.driver.browser.manage.add_cookie for system tests
    page.driver.browser.manage.add_cookie(
      name: 'session_token',
      value: session.id,
      path: '/',
      httponly: true
    )
  end

  def current_user
    return nil unless cookies.signed[:session_token]

    session = Session.find_by(id: cookies.signed[:session_token])
    session&.user
  end

  def sign_out
    delete sign_out_path
  end

end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
  config.include AuthenticationHelpers, type: :feature
  config.include AuthenticationHelpers, type: :system
end
