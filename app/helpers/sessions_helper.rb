module SessionsHelper
  def log_in(user)
    session[:user_id] = user.id
  end

  def remember(user)
    user.remember # get remember_token and remember_digest
    cookies.signed[:user_id] = { value: user.id, expires: 20.years.from_now.utc }
    cookies[:remember_token] = { value: user.remember_token, expires: 20.years.from_now.utc }
  end

  def current_user
    if (user_id = session[:user_id])
      @current_user ||= User.find_by(id: user_id)
    elsif (user_id = cookies.signed[:user_id])
      user = User.find_by(id: user_id)
      if user&.authenticated?(cookies[:remember_token])
        log_in user
        @current_user = user
      end
    end
  end

  def logged_in?
    !current_user.nil?
  end

  # delete remember_digest, remember_token, user_id
  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  def log_out
    forget(current_user)
    session.delete(:user_id)
    @current_user = nil
  end
end
