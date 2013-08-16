require 'net/http/post/multipart'
require 'multipart_post_helper.rb'

class OAuthTwitter < OAuthProvider
  NAME = "Twitter"
  
  def initialize
    super
    @provider_id = "twitter"
    @key = "YFU28RGQREFxKSww3jpA"
    @secret = "DOxGK2fsnptKKhbavqD5nixjoy7xH9g9KgJLDElc"
    @params = {:site => "https://api.twitter.com"}
    @api_userinfo = '/1.1/account/verify_credentials.json'
  end

  def parse_user_id(userinfo)
    @user_id = userinfo['screen_name']
    @username = userinfo['screen_name']
  end
   
  def get_user_url(user_id)
    ret = "http://twitter.com/#{user_id}"
  end
   
  def parse_user_default(userinfo)
    user_default = {}
    user_default[:username] = userinfo['screen_name'][0,20] if userinfo['screen_name']
    user_default[:bio] = userinfo['description'][0,160] if userinfo['description']
    user_default[:name] = userinfo['name'][0,20] if userinfo['name']
    user_default[:location] = userinfo['location'][0,45] if userinfo['location']
    #user_default[:web] = get_user_url(userinfo['screen_name'])[0,100]
    user_default[:web] = userinfo['url'][0,100] if userinfo['url']
    # should get big avatar by twitter api. e.g. http://api.twitter.com/1.1/users/profile_image?screen_name=twitterapi&size=bigger, size can be http://api.twitter.com/1.1/users/profile_image?screen_name=twitterapi&size=bigger(73*73) | normal(48*48) | mini(24*24) | original 
    user_default[:photo] = userinfo['profile_image_url'][0,500].sub("_normal.", ".") if userinfo['profile_image_url'] 
    user_default
  end
  
  def sync(upload_url, iu, setting)
    parameters = {:status => "##{iu.app.name} #{iu.content} #{upload_url}", :trim_user => true}
    access_token = OAuth::AccessToken.new(get_consumer, setting.get_token(@provider_id), setting.get_secret(@provider_id))
    resp = access_token.post("/1.1/statuses/update.json", parameters, {})
    resp
  end
  
# failed : sync twitter Net::HTTPUnauthorized: {"request":"\/statuses\/update_with_media.json","error":"Could not authenticate with OAuth."} 
#  def sync(upload_url, iu, setting)
#    status = "##{iu.app.name} #{iu.content} #{upload_url}"
#    #post status and upload photo    
#    image = iu.image || iu.app.icon
#    file = File.new("public#{image}", "rb")
#    url = URI.parse('http://api.twitter.com/statuses/update_with_media.json')
#    data = {"status" => status}
#    req = Net::HTTP::Post::Multipart.new url.request_uri, {
#      "media[]" => UploadIO.new(file, "image/jpeg", file.path)
#    }.merge(data)
#    @params = {:site => "http://api.twitter.com", :scheme => :header}
#    consumer = get_consumer
#    access_token = OAuth::AccessToken.new(consumer, setting.get_token(@provider_id), setting.get_secret(@provider_id))
#    consumer.sign!(req, access_token, :multipart_form_params => data)
#    resp = nil
#    Net::HTTP.new(url.host, url.port).start do |http|
##      resp = https("https://api.twitter.com").request(req) # process request
#      resp = http.request(req) # process request
#    end  
#    resp    
#  end
  
  def delete(status_id, setting)
    return unless status_id
    access_token = OAuth::AccessToken.new(get_consumer, setting.get_token(@provider_id), setting.get_secret(@provider_id))
    resp = access_token.post("/1.1/statuses/destroy/#{status_id}.json", {}, {})
    resp
  end

  def get_following_ids(user)
    ret = nil
    resp = get_api_access_token(user).get("/1.1/friends/list.json?count=#{FRIENDS_LIMIT}&skip_status=true&include_user_entities=false")
    if resp.class == Net::HTTPOK
      users = JSON.parse(resp.body)['users']
      ret = users.collect {|u| u['screen_name']}
    end
    ret
  end

  def get_follower_ids(user)
    ret = nil
    resp = get_api_access_token(user).get("/1.1/followers/list.json?count=#{FRIENDS_LIMIT}&skip_status=true&include_user_entities=false")
    if resp.class == Net::HTTPOK
      users = JSON.parse(resp.body)['users']
      ret = users.collect {|u| u['screen_name']}
    end
    ret
  end

  #get friends and turns them to hash array
  def get_following(user)
    ret = []
    resp = get_api_access_token(user).get("/1.1/friends/list.json?count=#{FRIENDS_LIMIT}&skip_status=true&include_user_entities=false")
    if resp.class == Net::HTTPOK
      users = JSON.parse(resp.body)['users']
      ret = users.collect{|u| {:name => u['name'], :avatar => u['profile_image_url'], :id => u['screen_name']}}
    end
    ret
  end
  
  def invite(user, screen_name, content)
    parameters = {:status => "@#{screen_name} #{content}", :trim_user => true}
#    access_token = OAuth::AccessToken.new(get_consumer, setting.get_token(@provider_id), setting.get_secret(@provider_id))
    get_api_access_token(user).post("/1.1/statuses/update.json", parameters, {})
  end

  def follow_on_sns(user, friend_screen_name)
#    data = "access_token=#{user.setting.oauth_sina}&screen_name=#{friend_screen_name}"
    parameters = {:screen_name => "#{friend_screen_name}"}
    access_token = OAuth::AccessToken.new(get_consumer, user.setting.get_token(@provider_id), user.setting.get_secret(@provider_id))
    resp = access_token.post("/1.1/friendships/create.json", parameters, {})
#    logger.error "#{Time.now.short_time} Custom log follow_on_sns: #{resp.body} "
  end

  def follow_official(user)
    follow_on_sns user, "swablyofficial"
  end

end