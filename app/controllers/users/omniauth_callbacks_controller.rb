
require 'pp'
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def twitter
    @user = User.find_for_twitter_oauth(request.env["omniauth.auth"], current_user)

    if @user.persisted?
      #ユーザがログイン済みなら   
   
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Twitter"
     
      
      #セッションにトークンとシークレットを保存
      session[:token] = request.env["omniauth.auth"]["credentials"]["token"]
      session[:secret] = request.env["omniauth.auth"]["credentials"]["secret"]

      sign_in_and_redirect @user, :event => :authentication
    else
      session["devise.twitter_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url
    end

  end
end
