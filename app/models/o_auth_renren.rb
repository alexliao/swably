require 'net/http/post/multipart'
require 'multipart_post_helper.rb'
class OAuthRenren < OAuthProvider
  NAME = "人人网"
  
  def initialize
    super
    @provider_id = "renren"
    @key = "fae136074a05461db3c014bc4b961b31"
    @secret = "ad5db4d389564e099f945152553def2a"
    @params = {:site => "https://graph.renren.com"}
    
    @api_get_session_key = "https://graph.renren.com/renren_api/session_key?oauth_token="
    @api_userinfo = '/account/verify_credentials.json'
  end

  def get_authorize_url(parameters = nil)
    #url = "https://graph.renren.com/oauth/authorize?client_id=#{@key}&response_type=code&scope=publish_feed&redirect_uri=#{get_callback}"
    url = "https://graph.renren.com/oauth/authorize?client_id=#{@key}&response_type=code&scope=photo_upload&redirect_uri=#{get_callback}"
    return url, nil
  end

  def authed(params)
    params[:code]
  end

  def access_token_str
    @access_token_str
  end

  def accept(params, request)
    url = "/oauth/token?client_id=#{@key}&client_secret=#{@secret}&redirect_uri=#{get_callback}&code=#{params[:code]}&grant_type=authorization_code"
    ses = https
    resp = ses.get(url)
    if resp.class == Net::HTTPOK
      ret = JSON.parse(resp.body)
      @access_token_str = ret['access_token']
      #expires_in = ret['expires_in']
      #refresh_token = ret['refresh_token']

      resp = call_api("users.getLoggedInUser", @access_token_str)
      if resp.class == Net::HTTPOK
        json = JSON.parse(resp.body)
        uid = json['uid']
        resp = call_api("users.getInfo", @access_token_str, {"uids" => uid, "fields" => "uid,name,headurl,hometown_location,work_history,university_history"})
        if resp.class == Net::HTTPOK
          @userinfo = JSON.parse(resp.body)[0]
          parse_user_id(@userinfo)
        end
      else
        err = "Get user info failed: " + resp.to_s
      end

#      if resp.class == Net::HTTPOK
#        @api_session = JSON.parse(resp.body)
#        if @api_session['expires_in'] > 0
#          session_key = @api_session['session_key']
#        else
#          err = "Session expired"
#        end
#      else
#        err = "Get session key failed"
#      end
      
#      resp = ses.get("/me?access_token=#{@access_token_str}")
#      if resp.class == Net::HTTPOK
#        @userinfo = JSON.parse(resp.body)
#        parse_user_id(@userinfo)
#        #prepare avatar
#        begin
#          resp = ses.get("/me/picture?access_token=#{@access_token_str}")
#          if resp.code.to_i == 302
#            @userinfo['picture'] = resp['location']
#          end
#        rescue
#        end
#      end
    else
      # The user might have rejected this application. Or there was some other error during the request.
      err = "Authentication failed: " + resp.to_s
    end
    err
  end 

  def parse_user_id(userinfo)
    @user_id = userinfo['uid']
    @username = userinfo['name']
  end
   
  def get_user_url(user_id)
    ret = "http://www.renren.com/profile.do?id=#{user_id}"
  end
   
  def parse_user_default(userinfo)
    user_default = {}
    user_default[:username] = "renren#{userinfo['uid']}"[0,20]
   
    bio = "" 
    bio += userinfo['work_history'][0]['company_name'] + "\n" if userinfo['work_history'] and userinfo['work_history'][0]
    bio += "#{userinfo['university_history'][0]['name']}#{userinfo['university_history'][0]['department']} #{userinfo['university_history'][0]['year']}" if userinfo['university_history'] and userinfo['university_history'][0]
    user_default[:bio] = bio[0,160]
    
    user_default[:name] = userinfo['name'][0,20]
    user_default[:location] = "#{userinfo['hometown_location']['province']} #{userinfo['hometown_location']['city']}" [0,45] if userinfo['hometown_location']
    user_default[:web] = get_user_url(userinfo['uid'])[0,100]
    user_default[:photo] = userinfo['headurl'][0,500] if userinfo['headurl']
    user_default
  end
  
# It works but renren.com doesn't approve this api
#  def sync(upload_url, iu, setting)
#    params = {}
#    params["name"] = "发布了新相片"
#    params["description"] = iu.caption
#    params["url"] = upload_url
#    params["image"] = "http://#{ENV['host']}#{iu.url}"
#    if iu.longitude && iu.latitude
#      #map_url = ERB::Util.url_encode("http://maps.google.com/?ll=#{iu.latitude},#{iu.longitude}&q=#{iu.latitude},#{iu.longitude}")
#      map_url = "http://maps.google.com/?q=#{iu.latitude},#{iu.longitude}"
#      params["action_name"] = "打开地图"
#      params["action_link"] = map_url
#    end
#    resp = call_api("feed.publishFeed", setting.oauth_renren, params)
#puts "feed.publishFeed"
#    resp
#  end

  def sync(upload_url, iu, setting)
    #upload photo    
    params = {}
    params["caption"] = iu.caption
    params = prepare_params("photos.upload", setting.oauth_renren, params)
    file = File.new("public#{iu.url}", "rb")
    uri = URI.parse("http://api.renren.com/restserver.do")
    req = Net::HTTP::Post::Multipart.new uri.request_uri, {
      "upload" => UploadIO.new(file, "image/jpeg", file.path)
    }.merge(params)
    #ses = Net::HTTP.new(uri.host, uri.port)
    #ses.post('/restserver.do', req)
    resp = nil
    Net::HTTP.new(uri.host, uri.port).start do |http|
      resp = http.request(req) # process request
    end  
    resp    
  end
  
  def get_following_ids(user)
    @friends = nil
    
    resp = call_api("friends.get", user.setting.oauth_renren)
#puts "friends.get"
#puts resp
    if resp.class == Net::HTTPOK
      users = JSON.parse(resp.body)
      @friends = users
    end
    @friends
  end

  def get_follower_ids(user)
    @friends
  end

protected
  def https
    uri = URI.parse("https://graph.renren.com/")
    ses = Net::HTTP.new(uri.host, uri.port)
    ses.use_ssl = true
    ses.verify_mode = OpenSSL::SSL::VERIFY_NONE
    ses
  end  
  
  def get_params_str(params, splitor = "")
    #(params.collect{|key, value| "#{key}=#{value}"}).join(splitor)
    (params.sort.collect{|item| "#{item[0]}=#{item[1]}"}).join(splitor)
  end

  def get_signature(params)
    base_str = get_params_str(params)+@secret
puts base_str
    Digest::MD5.hexdigest(base_str)
  end
  
  
  def prepare_params(method, access_token, params = {})
    params["format"] = "JSON"
    params["method"] = method
    params["v"] = "1.0"
    params["call_id"] = Time.now.to_i
    params["access_token"] = access_token
    params["sig"] = get_signature(params)
#puts params["sig"]    
    params
  end
  
  def call_api(method, access_token, params = {})
    uri = URI.parse("http://api.renren.com/")
    ses = Net::HTTP.new(uri.host, uri.port)
    ses.post('/restserver.do', get_params_str(prepare_params(method, access_token, params),"&"))
  end
end