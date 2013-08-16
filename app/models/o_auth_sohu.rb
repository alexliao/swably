require 'net/http/post/multipart'
require 'multipart_post_helper.rb'
class OAuthSohu < OAuthProvider
  NAME = "搜狐微博"
  
  def initialize
    super
    @provider_id = "sohu"
    @key = "oaejSOVoppEDNmabsu7v"
    @secret = "NKqv!ravfNST0KK9HVb0H!F-=cfblZs52V3^-o*^"
    @params = {:site => "http://api.t.sohu.com", :http_method => :get}
    @api_userinfo = '/account/verify_credentials.json'
  end

#  def get_authorize_url(parameters = nil)
#    url, token = super(parameters)
#    callback = get_callback(parameters)
#    url += "&oauth_callback=#{callback}"
#    return url, token
#  end

  def parse_user_id(userinfo)
    @user_id = userinfo['id']
    @username = userinfo['screen_name']
  end
   
  def get_user_url(user_id)
    ret = "http://t.sohu.com/u/#{user_id}"
  end
   
  def parse_user_default(userinfo)
    user_default = {}
    user_default[:username] = userinfo['screen_name'][0,20] if userinfo['screen_name']
    user_default[:bio] = userinfo['description'][0,160] if userinfo['description']
    user_default[:name] = userinfo['name'][0,20] if userinfo['name']
    user_default[:location] = userinfo['location'][0,45] if userinfo['location']
    user_default[:web] = userinfo['url'][0,100] if userinfo['url']
    user_default[:photo] = userinfo['profile_image_url'][0,500] if userinfo['profile_image_url']
    user_default
  end
  
  def sync(upload_url, iu, setting)
    caption = iu.caption
    caption = "发布了新相片" if caption.blank?
    status = caption + " " + upload_url
    file = File.new("public#{iu.url}", "rb")
    url = URI.parse('http://api.t.sohu.com/statuses/upload.json')
    data = {"status" => ERB::Util.url_encode(status)}
    #data.merge!({"lat" => iu.latitude, "long" => iu.longitude}) if iu.latitude && iu.longitude # sohu doen't support location
    req = Net::HTTP::Post::Multipart.new url.request_uri, {
      "pic" => UploadIO.new(file, "image/jpeg", file.path)
    }.merge(data)
    consumer = get_consumer
    access_token = OAuth::AccessToken.new(consumer, setting.get_token(@provider_id), setting.get_secret(@provider_id))
    consumer.sign!(req, access_token, :multipart_form_params => data)
    resp = nil
    Net::HTTP.new(url.host, url.port).start do |http|
      resp = http.request(req) # process request
    end  
    resp    
  end
  
  def get_following_ids(user)
    ret = nil
    resp = get_api_access_token(user).get("/statuses/friends.json?count=#{FRIENDS_LIMIT}")
    if resp.class == Net::HTTPOK
      users = JSON.parse(resp.body)
      ret = users.collect {|u| u['id']}
    end
    ret
  end

  def get_follower_ids(user)
    ret = nil
    resp = get_api_access_token(user).get("/statuses/followers.json?count=#{FRIENDS_LIMIT}")
    if resp.class == Net::HTTPOK
      users = JSON.parse(resp.body)
      ret = users.collect {|u| u['id']}
    end
    ret
  end

end