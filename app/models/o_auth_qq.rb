# encoding: utf-8 
require 'net/http/post/multipart'
require 'multipart_post_helper.rb'
class OAuthQq < OAuthProvider
  NAME = "腾讯微博"
  
  def initialize
    super
    @provider_id = "qq"
    @key = "801461555"
    @secret = "6de71ecd0a73eda6b6fc5202421f37da"
    @params = {:site => "https://open.t.qq.com", :scheme => :query_string, :http_method => :get, :request_token_path => "/cgi-bin/request_token", :access_token_path => "/cgi-bin/access_token", :authorize_path=> "/cgi-bin/authorize"}
    @api_site = 'http://open.t.qq.com'
    @api_userinfo = '/api/user/info?format=json'
  end

  # Tencent require nonce not more than 32 bytes
#  def get_options
#    nonce = Base64.encode64(OpenSSL::Random.random_bytes(32)).gsub(/\W/, '')[0,32]
#    {:nonce => nonce}
#  end

  def parse_user_id(userinfo)
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

# sync without picture, it works.
  def sync(upload_url, iu, setting)
    caption = iu.caption
    caption = "发布了新相片" if caption.blank?
    status = caption + " " + upload_url
    parameters = {:format => 'json', :content => status, :clientip => iu.client_ip, :wei => iu.latitude, :jing => iu.longitude}
    @params = {:site => @api_site, :scheme => :query_string, :http_method => :post}
    access_token = OAuth::AccessToken.new(get_consumer, setting.get_token(@provider_id), setting.get_secret(@provider_id))
    resp = access_token.post("/api/t/add", parameters, {})
    resp
  end

  
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
  
end