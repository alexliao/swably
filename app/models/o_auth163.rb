require 'net/http/post/multipart'
require 'multipart_post_helper.rb'
class OAuth163 < OAuthProvider
  NAME = "网易微博"
  
  def initialize
    super
    @provider_id = "163"
    @key = "1HGaOdGeGiE2LZ74"
    @secret = "Exn5jhes6kEUGOKsZdLoyNw6dJwPVIL7"
    @params = {:site => "http://api.t.163.com", :authorize_path=> "/oauth/authenticate"}
    @api_userinfo = '/account/verify_credentials.json'
  end

  def authed(params)
    params[:oauth_token]
  end

  def parse_user_id(userinfo)
    @user_id = userinfo['screen_name']
    @username = userinfo['screen_name']
  end
   
  def get_user_url(user_id)
    ret = "http://t.163.com/#{user_id}"
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
    resp = nil
    pic_url = nil
    consumer = get_consumer
    caption = iu.caption
    caption = "发布了新相片" if caption.blank?
    status = caption + " " + upload_url
    file = File.new("public#{iu.url}", "rb")
    access_token = OAuth::AccessToken.new(consumer, setting.get_token(@provider_id), setting.get_secret(@provider_id))

    # upload image
    url = URI.parse('http://api.t.163.com/statuses/upload.json')
    req = Net::HTTP::Post::Multipart.new url.request_uri, {
      "pic" => UploadIO.new(file, "image/jpeg", file.path)
    }
    consumer.sign!(req, access_token, :multipart_form_params => {})
    Net::HTTP.new(url.host, url.port).start do |http|
      resp = http.request(req) # process request
    end
    # post tweet
    if resp.class == Net::HTTPOK
      pic_url = JSON.parse(resp.body)['upload_image_url'] 
      parameters = {:status => status + " " + pic_url, :lat => iu.latitude, :long => iu.longitude}
      resp = access_token.post("http://api.t.163.com/statuses/update.json", parameters, {})
    end
      
    resp    
  end

  def get_following_ids(user)
    ret = nil
    resp = get_api_access_token(user).get("/statuses/friends.json?count=#{FRIENDS_LIMIT}")
    if resp.class == Net::HTTPOK
      users = JSON.parse(resp.body)["users"]
      ret = users.collect {|u| u['screen_name']}
    end
    ret
  end

  def get_follower_ids(user)
    ret = nil
    resp = get_api_access_token(user).get("/statuses/followers.json?count=#{FRIENDS_LIMIT}")
    if resp.class == Net::HTTPOK
      users = JSON.parse(resp.body)["users"]
      ret = users.collect {|u| u['screen_name']}
    end
    ret
  end
  
end