# frozen_string_literal: true

class Feed
  def initialize(type, account)
    @type    = type
    @account = account
  end

  def get(limit, max_id = nil, since_id = nil)
    max_id     = '+inf' if max_id.blank?
    since_id   = '-inf' if since_id.blank?
    unhydrated = redis.zrevrangebyscore(key, "(#{max_id}", "(#{since_id}", limit: [0, limit], with_scores: true).map(&:last).map(&:to_i)
    client = @account.twitter_accounts.first&.client
    if client && Time.zone.now + 3.minutes < client.last_updated_at
      app = Doorkeeper::Application.first
      client.home_timeline.each do |tweet|
        user = tweet.user
        account = Account.find_or_create_by(domain: 'twitter.com', username: user.screen_name) do |a|
          a.display_name = user.name
          a.note = user.description
          a.url = "https://twitter.com/#{user.screen_name}"
          a.avatar_remote_url = user.profile_image_uri_https(:bigger).to_s
        end
        Status.find_or_create_by(url: tweet.url.to_s) do |s|
          s.account = account
          s.visibility = :private
          s.text = tweet.text
          s.application = app
        end
      end
      @account.twitter_accounts.first.update(last_updated_at: Time.zone.now)
    end

    status_map = Status.where(id: unhydrated).cache_ids.map { |s| [s.id, s] }.to_h
    unhydrated.map { |id| status_map[id] }.compact
  end

  private

  def key
    FeedManager.instance.key(@type, @account.id)
  end

  def redis
    Redis.current
  end
end
