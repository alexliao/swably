# encoding: utf-8 
require 'net/http/post/multipart'
require 'multipart_post_helper.rb'
class OAuthSina < OAuth2Provider
  NAME = "新浪微博"
  
  def initialize
    super
    @provider_id = "sina"
    @key = "2808291982"
    @secret = "bbedd16d97365e498fceb6f2f2d94afc"
#    @key = "179937101"
#    @secret = "808df73bab895435cde7e1a4131a8ab6"
    @params = {:site => "http://api.t.sina.com.cn", :scheme => :query_string}
#    @api_userinfo = '/account/verify_credentials.json'
    @api_scheme = :header
    @api_site = "https://api.weibo.com"
    @path_authorize = "/oauth2/authorize"
    @path_access_token = "/oauth2/access_token"
  end

  def parse_user_id(userinfo)
    #@user_id = userinfo['domain'].blank? ? userinfo['id'] : userinfo['domain']
    @user_id = userinfo['id']
    @username = userinfo['screen_name']
  end
   
  def get_user_url(user_id)
    ret = "http://t.sina.com.cn/#{user_id}"
  end
   
  def parse_user_default(userinfo)
    user_default = {}
    user_id = (userinfo['domain'].blank? ? userinfo['id'] : userinfo['domain']).to_s
    user_default[:username] = userinfo['screen_name'] if userinfo['screen_name']
    user_default[:bio] = userinfo['description'][0,160] if userinfo['description']
    user_default[:name] = userinfo['name'] if userinfo['name']
    user_default[:location] = userinfo['location'][0,45] if userinfo['location']
    user_default[:web] = userinfo['url'][0,100] if userinfo['url']
    user_default[:photo] = userinfo['avatar_large'][0,500] if userinfo['avatar_large']
    user_default
  end
  
  def sync(upload_url, iu, setting)
    #post status
    status = ERB::Util.url_encode("##{iu.app.local_name('zh')}# #{iu.content} #{upload_url}")
#    data = "access_token=#{setting.oauth_sina}&status=#{status}"
#    resp = https(@api_site).post("/2/statuses/update.json", data)
#    resp
    #post status and upload photo    
    image = iu.image || iu.app.icon
    file = File.new("public#{image}", "rb")
    url = URI.parse('https://upload.api.weibo.com/2/statuses/upload.json')
    data = {"status" => status, "access_token" => setting.oauth_sina}
    req = Net::HTTP::Post::Multipart.new url.request_uri, {
      "pic" => UploadIO.new(file, "image/jpeg", file.path)
    }.merge(data)
    resp = https("https://upload.api.weibo.com").request(req) 
    resp    
  end

  def delete(status_id, setting)
    return unless status_id
    data = "access_token=#{setting.oauth_sina}&id=#{status_id}"
    resp = https(@api_site).post("/2/statuses/destroy.json", data)
    resp
  end

  def get_user(access_token)
    ses = https(@api_site)
    resp = ses.get("/2/account/get_uid.json?access_token=#{access_token}")
puts resp.class
puts resp.code
    if resp.class == Net::HTTPOK
#puts "resp.body"
#puts resp.body
      uid = JSON.parse(resp.body)['uid']
      resp = ses.get("/2/users/show.json?uid=#{uid}&access_token=#{access_token}")
      if resp.class == Net::HTTPOK
        @userinfo = JSON.parse(resp.body)
        parse_user_id(@userinfo)
      else
        err = resp.body
      end
    elsif resp.class == Net::HTTPForbidden
      err = "新浪微博尚未审核通过Swably的接入请求，暂时无法登录，请过几日重试。虽然不能登录，但您仍然可以匿名使用Swably的部分功能，如上传，下载和发送应用"
    else
      err = resp.body
    end
    err
  end
 
  def get_following_ids(user)
    ret = nil
    resp = https(@api_site).get("/2/friendships/friends.json?uid=#{user.setting.user_id_sina}&count=#{FRIENDS_LIMIT}&access_token=#{user.setting.oauth_sina}")
    if resp.class == Net::HTTPOK
      users = JSON.parse(resp.body)['users']
      ret = users.collect {|u| u['id']}
    end
    ret
  end

  def get_follower_ids(user)
    ret = nil
    resp = https(@api_site).get("/2/friendships/follwers.json?uid=#{user.setting.user_id_sina}&count=#{FRIENDS_LIMIT}&access_token=#{user.setting.oauth_sina}")
    if resp.class == Net::HTTPOK
      users = JSON.parse(resp.body)['users']
      ret = users.collect {|u| u['id']}
    end
    ret
  end
 
  #get friends and turns them to hash array
  def get_following(user)
    ret = []
    resp = https(@api_site).get("/2/friendships/friends.json?uid=#{user.setting.user_id_sina}&count=#{FRIENDS_LIMIT}&access_token=#{user.setting.oauth_sina}")
#puts resp.body
    if resp.class == Net::HTTPOK
      users = JSON.parse(resp.body)['users']
      ret = users.collect{|u| {:name => u['name'], :avatar => u['avatar_large'], :id => u['screen_name']}}
    end
    ret
  end
  
  # not tested
  #get friends who followed with me each other so that can send private message to them.
  def get_friends(user)
    ret = []
    resp = https(@api_site).get("/2/friendships/friends/bilateral.json?uid=#{user.setting.user_id_sina}&count=#{FRIENDS_LIMIT}&access_token=#{user.setting.oauth_sina}")
#puts resp.body
    if resp.class == Net::HTTPOK
      users = JSON.parse(resp.body)['users']
      ret = users.collect{|u| {:name => u['name'], :avatar => u['avatar_large'], :id => u['screen_name']}}
    end
    ret
  end


  def invite(user, screen_name, content)
    status = ERB::Util.url_encode("@#{screen_name} #{content}")
#    access_token = OAuth::AccessToken.new(get_consumer, setting.get_token(@provider_id), setting.get_secret(@provider_id))
    data = "access_token=#{user.setting.oauth_sina}&status=#{status}"
    https(@api_site).post("/2/statuses/update.json", data)
  end

  def get_callback(parameters = nil)
    host = (Rails.env == "development") ? "192.168.2.107:2001" : ENV['host']
    callback = ("http://#{host}/connections/accept/#{@provider_id}")
    callback
  end

  def follow_on_sns(user, friend_screen_name)
    data = "access_token=#{user.setting.oauth_sina}&screen_name=#{friend_screen_name}"
    resp = https(@api_site).post("/2/friendships/create.json", data)
    # logger.error "#{Time.now.short_time} Custom log follow_on_sns: #{resp.body} "
  end

  def follow_official(user)
    follow_on_sns user, "Swably"
  end

end