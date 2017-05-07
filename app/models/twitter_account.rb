# == Schema Information
#
# Table name: twitter_accounts
#
#  id                  :integer          not null, primary key
#  account_id          :integer
#  name                :string
#  access_token        :string
#  access_token_secret :string
#  last_updated_at     :datetime         not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class TwitterAccount < ApplicationRecord
  belongs_to :account

  def client
    @client ||= Twitter::REST::Client.new do |c|
      c.consumer_key = ENV['TWITTER_CONSUMER_KEY']
      c.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
      c.access_token = access_token
      c.access_token_secret = access_token_secret
    end
  end

  def assign_name
    self.name = client.user.screen_name
  end
end
