module Settings
  class TwitterAccountsController < ApplicationController
    layout 'admin'

    before_action :authenticate_user!
    before_action :set_account
    before_action :set_oauth_consumer, only: [:new, :oauth]

    def index
      @twitter_accounts = @account.twitter_accounts
    end

    def new
      request_token = @consumer.get_request_token(oauth_callback: oauth_settings_twitter_accounts_url)
      session[:request_token] = request_token.token
      session[:request_token_secret] = request_token.secret
      redirect_to request_token.authorize_url(oauth_callback: oauth_settings_twitter_accounts_url)
    end

    def oauth
      request_token = OAuth::RequestToken.new(@consumer,
                                              session[:request_token],
                                              session[:request_token_secret])
      access_token = request_token.get_access_token({},
                                                     oauth_verifier: params[:oauth_verifier],
                                                     oauth_token: params[:oauth_token])
      session[:access_token] = access_token.token
      session[:access_token_secret] = access_token.secret

      @ta = @account.twitter_accounts.new(access_token: access_token.token,
                                          access_token_secret: access_token.secret)
      @ta.assign_name
      @ta.save
      redirect_to settings_twitter_accounts_path
    end

    def destroy
      @twitter_account = @account.twitter_accounts.find(params[:id])
      @twitter_account.destroy
      redirect_to settings_twitter_accounts_path
    end

    private

    def set_account
      @account = current_user.account
    end

    def set_oauth_consumer
      @consumer = OAuth::Consumer.new(ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET'], { site: 'https://api.twitter.com', scheme: :header })
    end
  end
end
