class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
    
  def facebook
    _third_party_callback
  end

  def google
    _third_party_callback
  end

  def twitter
    _third_party_callback
  end

  def yahoo
    _third_party_callback
  end

  protected

  def _third_party_callback

    @user = User.find_for_third_party_auth(env["omniauth.auth"], current_user)
    
    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => env["omniauth.auth"]["provider"]
      sign_in @user, :event => :authentication
      if session.has_key?('position_to_be_published')
        session['reify_activities'] = true 
      end

    if @user && session[:domain] != @user.domain_id
      @user.domain_id = session[:domain]
      @user.save
    end

    else
      session["devise.third_party"] = env["omniauth.auth"]
      #redirect_to new_user_registration_url
    end

    @redirect_to = session[:return_to] || root_path
    render :inline =>
      '<script type="text/javascript">' +
      '  window.close();' +
      '  window.opener.location = "<%= @redirect_to %>";' +
      '</script>'

  end
 

end
