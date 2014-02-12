require 'oauth'  
require 'json'
class OAuthProvider
  # include GetText
  include ActionView::Helpers::TextHelper
#  attr_accessor provider_id
#  attr_accessor provider_name
#  attr_accessor key
#  attr_accessor secret
#  attr_accessor params
  DISABLE_AUTO_FOLLOW = false  
  FRIENDS_LIMIT = 200
  attr_reader :user_id
  attr_reader :username
  attr_accessor :request
  
  def initialize
    @options = {}
  end  

  def self.get_instance(provider_id)
    eval("OAuth#{provider_id.capitalize}.new")
  end

  def self.get_name(provider_id)
    eval("OAuth#{provider_id.capitalize}::NAME")
  end

  def self.get_disable_auto_follow(provider_id)
    eval("OAuth#{provider_id.capitalize}::DISABLE_AUTO_FOLLOW")
  end
  
  def get_consumer(params = {})
    params = @params.merge(params)
    OAuth::Consumer.new(@key, @secret, params)
  end  


  def get_callback(parameters = nil)
    host = (Rails.env == "development") ? "172.24.1.100:3000" : ENV['host']
#    host = (RAILS_ENV == "development") ? "localhost:2001" : ENV['host']
#host = "192.168.1.101:5021"
    callback = ("http://#{host}/connections/accept/#{@provider_id}")
#host = ENV['host']
#callback = ("http://#{host}/aconnections/accept/#{@provider_id}")
    callback += "?#{parameters}" if parameters
# oauth call failed if add encode    ERB::Util.url_encode(callback)
    callback
  end

  def get_options
    {}
  end
  
  def get_authorize_url(parameters = nil)
    callback = get_callback(parameters)
    consumer = get_consumer
    options = get_options
    options[:oauth_callback] = callback
    request_token = consumer.get_request_token(options)
    url = request_token.authorize_url
    url += "&oauth_callback=#{callback}" unless url.match("&oauth_callback")

    # return url, {:token => request_token.token, :secret => request_token.secret}
    return url
  end

  def authed(params)
    params[:oauth_verifier]
  end
   
  def get_userinfo
    access_token = @access_token
    if @api_site
      @params[:site] = @api_site
      access_token = OAuth::AccessToken.new(get_consumer, @access_token.token, @access_token.secret)
    end
    access_token.get(@api_userinfo)
  end 
  
  #virtual def parse_userinfo(resp)

  def access_token_str(logger = nil)

# logger.error(@access_token.to_s)
# logger.error(@access_token.token)

    @access_token.token+" "+@access_token.secret
  end
  def get_access_token_by(str)
    a = str.split(" ")
    options = {}
    options[:site] = @api_site if @api_site
    options[:scheme] = @api_scheme if @api_scheme
    consumer = get_consumer(options)
    OAuth::AccessToken.new(consumer, a[0], a[1])
  end
   
#  # accept for web site
#  def accept(params, request)
#    consumer = get_consumer
#    begin
#      request_token = OAuth::RequestToken.new(consumer,  request[:token], request[:secret])  
#      options = get_options
#      options[:oauth_verifier] = params[:oauth_verifier]
#      @access_token = request_token.get_access_token(options)
#    rescue
#    end
#    if @access_token
#      resp = get_userinfo
#puts "get_userinfo resp.body:"
#puts resp.body
#      case resp
#      when Net::HTTPSuccess
#        @userinfo = JSON.parse(resp.body)
#        parse_user_id(@userinfo)
#      else
#        err = "Can't get user info: <br/>#{resp.body}"
#      end
#    else
#      # The user might have rejected this application. Or there was some other error during the request.
#      err = _("Authorization failed")
#    end
#    err
#  end 
  
  # oauth 1.0 style implementation for App 
  def accept(params)
    consumer = get_consumer
    begin
      # request_token = OAuth::RequestToken.new(consumer,  request[:token], request[:secret])  
      request_token = OAuth::RequestToken.new(consumer,  params[:oauth_token], nil)  
      options = get_options
      options[:oauth_verifier] = params[:oauth_verifier]
      @access_token = request_token.get_access_token(options)
    rescue
    end
    unless @access_token
      # The user might have rejected this application. Or there was some other error during the request.
      err = "Authorization failed"
    end
    err
  end 

  # oauth 1 implementation compatible with oauth 2 style
  def get_user(access_token_str)
    @access_token = get_access_token_by(access_token_str)
    resp = get_userinfo
    case resp
    when Net::HTTPSuccess
      @userinfo = JSON.parse(resp.body)
      parse_user_id(@userinfo)
    else
      err = "Can't get user info: <br/>#{resp.body}"
    end
    err
  end
 
  def user_default
    ret = {}
    #begin
      ret = parse_user_default(@userinfo)
    #rescue Exception => e
      #logger.error("#{Time.now.short_time} Custom log: Exception in OAuthProvider::user_default: " + e)
    #end
    ret[:bio] = strip_tags(ret[:bio]) if ret[:bio]
    ret[:plain_password] ||= "1234567890987654321"
    ret
  end  
  
  # sync social graph, including followings and followers
  def sync_graph(user)
    begin
      following_ids = get_following_ids(user)
      puts "#{following_ids.size} followings" if following_ids
      fo_count = follow(user, following_ids)
      puts "auto following #{fo_count}"
      follower_ids = get_follower_ids(user)
      puts "#{follower_ids.size} followers" if follower_ids
      befo_count = befollow(user, follower_ids)
      puts "auto be followed by #{befo_count}"
    rescue Exception => e
      puts e
    end
  end

  def get_api_access_token(user)
#    options = {}
#    options[:site] = @api_site if @api_site
#    options[:scheme] = @api_scheme if @api_scheme
#    consumer = get_consumer(options)
#    OAuth::AccessToken.new(consumer, user.setting.get_token(@provider_id), user.setting.get_secret(@provider_id))
     str = user.setting.get_token(@provider_id) + " " + user.setting.get_secret(@provider_id)    
     get_access_token_by(str)
  end
  
  def follow(user, ids)
    return unless ids
    return unless ids.size > 0
    count = 0
    ids_str = ids.collect{|id| "'#{id}'"}.join(",")
puts ids_str
    #Setting.find_by_sql("select u.id from settings s join users u on u.id=s.user_id where s.user_id_#(@provider_id) and oauth_#(@provider_id) is not null in (#{ids_str})")
    followings = User.find_by_sql("select u.* from settings s left join follows f on f.following_id=s.user_id and f.user_id = #{user.id} join users u on s.user_id=u.id where f.following_id is null and u.enabled=1 and s.oauth_#{@provider_id} is not null and s.user_id_#{@provider_id} in (#{ids_str})")
    followings.each do | following |
      user.try_follow(following)
      count += 1
    end
    count
  end
  
  def befollow(user, ids)
    return unless ids
    return unless ids.size > 0
    count = 0
    ids_str = ids.collect{|id| "'#{id}'"}.join(",")
puts ids_str
    followers = User.find_by_sql("select u.* from settings s left join follows f on f.user_id=s.user_id and f.following_id = #{user.id} join users u on s.user_id=u.id where f.user_id is null and u.enabled=1 and s.oauth_#{@provider_id} is not null and s.user_id_#{@provider_id} in (#{ids_str})")
    followers.each do | follower |
      follower.try_follow(user) if follower.get_option_auto_follow(@provider_id)
      count += 1
    end
    count
  end

  def get_status_id(json)
    json["id"]    
  end

protected
  def https(host)
    uri = URI.parse(host)
    ses = Net::HTTP.new(uri.host, uri.port)
    ses.use_ssl = true
    ses.verify_mode = OpenSSL::SSL::VERIFY_NONE
    ses
  end



end


# fix for OAuth lib generate nonce
module OAuth
  module Helper
    extend self

    def generate_key(size=32)
      Base64.encode64(OpenSSL::Random.random_bytes(size)).gsub(/\W/, '')[0,size]
    end
  end
end