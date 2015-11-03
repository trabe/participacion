class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  # TODO: Get name and email from cas.udc
  def cas
    @user = User.find_for_oauth(env["omniauth.auth"], current_user)

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: t('omniauth.cas.user_kind') ) if is_navigational_format?
    else
      session["devise.cas_data"] = env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end

  def after_sign_in_path_for(resource)
    if resource.email_provided?
      super(resource)
    else
      finish_signup_path
    end
  end

end
