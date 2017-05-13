# frozen_string_literal: true

class Feed
  def initialize(type, account)
    @type    = type
    @account = account
  end

  def get(limit, max_id = nil, since_id = nil)
    max_id     = '+inf' if max_id.blank?
    since_id   = '-inf' if since_id.blank?
    if twitter_account = @account.twitter_accounts.first
      if twitter_account.last_updated_at + 3.minutes < Time.zone.now
        if client = twitter_account.client
          app = Doorkeeper::Application.first
          accounts = []
          client.home_timeline.each do |tweet|
            user = tweet.user

            account = Account.find_or_create_by(domain: 'twitter.com', username: user.screen_name) do |a|
              a.display_name = user.name
              a.note = user.description || ' '
              a.url = "https://twitter.com/#{user.screen_name}"
              a.avatar_remote_url = user.profile_image_uri_https(:bigger).to_s
            end
            accounts << account
            status = Status.find_or_initialize_by(url: tweet.url.to_s) do |s|
              s.account = account
              s.visibility = :private
              s.text = tweet.text
              s.application = app
            end
            redis.zadd(key, status.id, status.id) if status.new_record? && status.save
          end
          accounts.each do |account|
            @account.active_relationships.find_or_create_by(target_account: account)
          end
          twitter_account.update(last_updated_at: Time.zone.now)
        end
      end
    end

    unhydrated = redis.zrevrangebyscore(key, "(#{max_id}", "(#{since_id}", limit: [0, limit], with_scores: true).map(&:last).map(&:to_i)

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
