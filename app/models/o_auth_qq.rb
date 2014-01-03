# encoding: utf-8 
require 'net/http/post/multipart'
require 'multipart_post_helper.rb'
require 'rack'

class OAuthQq < OAuth2Provider
  NAME = "腾讯微博"
  
  def initialize
    super
    @provider_id = "qq"
    @key = "801461555"
    @secret = "6de71ecd0a73eda6b6fc5202421f37da"
    @params = {:site => "https://open.t.qq.com", :scheme => :query_string, :http_method => :get, :request_token_path => "/cgi-bin/request_token", :access_token_path => "/cgi-bin/access_token", :authorize_path=> "/cgi-bin/authorize"}
    @api_site = 'https://open.t.qq.com'
    @path_authorize = "/cgi-bin/oauth2/authorize"
    @path_access_token = "/cgi-bin/oauth2/access_token"
    @api_userinfo = '/api/user/info?format=json'
  end

  # Tencent require nonce not more than 32 bytes
#  def get_options
#    nonce = Base64.encode64(OpenSSL::Random.random_bytes(32)).gsub(/\W/, '')[0,32]
#    {:nonce => nonce}
#  end

  # Tencent return format is not json 
  def accept(params)
    callback=ERB::Util.url_encode(get_callback("next=#{params[:next]}"))
    ses = https(@api_site)
    resp = ses.post(@path_access_token,"client_id=#{@key}&client_secret=#{@secret}&redirect_uri=#{callback}&code=#{params[:code]}&grant_type=authorization_code")
    if resp.class == Net::HTTPOK
      params = Rack::Utils.parse_nested_query resp.body
      # Tencent api require openid included in url params, so save it into access_token_str in database
      @access_token_str = "#{params['access_token']} #{params['openid']}" # default is online access_token which will expires in 3 months
#      err = get_user(@access_token_str)
    else
      # The user might have rejected this application. Or there was some other error during the request.
      err = resp.body
    end
    err
  end 

  def get_user(access_token_str)
    ses = https(@api_site)
    resp = ses.get("#{@api_userinfo}&#{common_params(access_token_str)}")
    if resp.class == Net::HTTPOK
      @userinfo = JSON.parse(resp.body)
      parse_user_id(@userinfo)
    else
      err = resp.body
    end
    err
  end


  def parse_user_id(userinfo)
puts "------------------"
puts userinfo
    @user_id = userinfo['data']['name']
    @username = userinfo['data']['name']
  end
   
  def get_user_url(user_id)
    ret = "http://t.qq.com/#{user_id}"
  end
   
  def parse_user_default(userinfo)
    user_default = {}
    user_default[:username] = userinfo['data']['name'][0,20] if userinfo['data'] and userinfo['data']['name']
    user_default[:name] = userinfo['data']['nick'][0,20] if userinfo['data'] and !userinfo['data']['nick'].blank?
    user_default[:name] = nil if user_default[:name] == user_default[:username]
    user_default[:bio] = userinfo['data']['introduction'][0,160] if userinfo['data'] and userinfo['data']['introduction']
    user_default[:location] = userinfo['data']['location'][0,160] if userinfo['data'] and userinfo['data']['location']
    user_default[:photo] = userinfo['data']['head']+"/180" if userinfo['data'] and !userinfo['data']['head'].blank? 
    user_default
  end

  def get_status_id(json)
    json["data"]["id"]    
  end

# sync without picture, it works.
  def sync(upload_url, iu, setting)
    status = ERB::Util.url_encode("##{iu.app.local_name('zh')}# #{iu.content} #{upload_url}")
    data = "content=#{status}&#{common_params(setting.oauth_qq)}"
    resp = https(@api_site).post("/api/t/add", data)
    resp
  end

  def delete(status_id, setting)
    return unless status_id
    data = "id=#{status_id}&#{common_params(setting.oauth_qq)}"
    resp = https(@api_site).post("/api/t/del", data)
    resp
  end

#   def sync(upload_url, iu, setting)
#     #post status
#     status = ERB::Util.url_encode("##{iu.app.local_name('zh')}# #{iu.content} #{upload_url}")
# #    data = "access_token=#{setting.oauth_sina}&status=#{status}"
# #    resp = https(@api_site).post("/2/statuses/update.json", data)
# #    resp
#     #post status and upload photo    
#     image = iu.image || iu.app.icon
#     file = File.new("public#{image}", "rb")
#     url = URI.parse('https://upload.api.weibo.com/2/statuses/upload.json')
#     data = {"status" => status, "access_token" => setting.oauth_sina}
#     req = Net::HTTP::Post::Multipart.new url.request_uri, {
#       "pic" => UploadIO.new(file, "image/jpeg", file.path)
#     }.merge(data)
#     resp = https("https://upload.api.weibo.com").request(req) 
#     resp    
#   end

  
#  def sync(upload_url, iu, setting)
#    caption = iu.caption
#    caption = "发布了新相片" if caption.blank?
#    status = caption + " " + upload_url
##post status and upload photo    
##    file = File.new("public#{iu.url}", "rb")
#    data = {"format" => "json", "content" => status, "clientip" => "127.0.0.1"}
#    data.merge!({"wei" => iu.latitude, "jing" => iu.longitude}) if iu.latitude && iu.longitude
##    req = Net::HTTP::Post::Multipart.new url.request_uri, {
##      "pic" => UploadIO.new(file, "image/jpeg", file.path)
##    }.merge(data)
#    status="ttt"    
#    #url = URI.parse("http://open.t.qq.com/api/t/add_pic?format=json&content=#{status}&clientip=&wei=#{iu.latitude}&jing=#{iu.longitude}")
#    url = URI.parse("http://open.t.qq.com/api/t/add_pic?format=json&content=#{status}")
#puts url.request_uri
#    aTEMP_FILE = "temp.txt"
#    File.open(aTEMP_FILE, "w") {|f| f << "1234567890"}
#    @io = File.open(aTEMP_FILE)
#    UploadIO.convert! @io, "image/jpeg", aTEMP_FILE, aTEMP_FILE
#    req = Net::HTTP::Post::Multipart.new url.request_uri, {
#      #"pic" => UploadIO.new(file, "image/jpeg", file.path)
#      "pic" => @io
#    }.merge(data)
##puts req.methods
#puts req.content_type
#puts req.content_length
#puts req.path
##body = req.body_stream.read
##puts body
#
##    @params[:site] = @api_site
##    consumer = get_consumer
##    access_token = OAuth::AccessToken.new(consumer, setting.get_token(@provider_id), setting.get_secret(@provider_id))
##    consumer.sign!(req, access_token)
#    resp = nil
#    Net::HTTP.new(url.host, url.port).start do |http|
#      resp = http.request(req) # process request
#    end  
#    resp    
#  end


  def get_following_ids(user)
    ret = nil
    resp = get_api_access_token(user).get("/api/friends/idollist?format=json&reqnum=#{FRIENDS_LIMIT}")
    if resp.class == Net::HTTPOK
      users = JSON.parse(resp.body)["data"]["info"]
      ret = users.collect {|u| u['name']}
    end
    ret
  end

  def get_follower_ids(user)
    ret = nil
    resp = get_api_access_token(user).get("/api/friends/fanslist?format=json&reqnum=#{FRIENDS_LIMIT}")
#puts resp
    if resp.class == Net::HTTPOK
      users = JSON.parse(resp.body)["data"]["info"]
      ret = users.collect {|u| u['name']}
    end
    ret
  end

  def follow_official(user)
    # follow_on_sns user, "Swably"
  end

  
protected
  def common_params(access_token_str)
    clientip = request.nil? ? nil : request.remote_ip
    "access_token=#{get_api_access_token(access_token_str)}&openid=#{get_api_openid(access_token_str)}&oauth_consumer_key=#{@key}&oauth_version=2.a&scope=all&format=json&clientip=#{clientip}"
  end

  def get_api_access_token(access_token_str)
    access_token_str.split(" ")[0]
  end

  def get_api_openid(access_token_str)
    access_token_str.split(" ")[1]
  end

end
