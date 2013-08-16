require 'oauth/signature/rsa/sha1'
require 'net/https'
require 'net/http'
class OAuthPlus < OAuth2Provider
  NAME = "Google+"
  
  def initialize
    super
    @provider_id = "plus"
    @key = "364382596274.apps.googleusercontent.com"
    @secret = "Zzb7gETSx-qaS7P_3veq1gc2"
    @api_site = "https://www.googleapis.com"
  end

  def parse_user_id(userinfo)
    @user_id = userinfo['id']
    @username = userinfo['name']
  end
   
  def get_user_url(user_id)
    ret = "https://plus.google.com/#{user_id}"
  end
   
  def parse_user_default(userinfo)
    user_default = {}
    user_default[:name] = userinfo['name'][0,20] if userinfo['name']
#    user_default[:bio] = userinfo['aboutMe'][0,160] if userinfo['aboutMe']
    #user_default[:web] = get_user_url(userinfo['data']['id'])[0,100] if userinfo['data'] and userinfo['data']['id']
    user_default[:photo] = userinfo['picture'] if userinfo['picture']
    user_default[:email] = userinfo['email'][0,100] if userinfo['email']
    user_default[:username] = user_default[:email].split("@")[0][0,20] if user_default[:email]
    user_default[:bio] = userinfo['bio'][0,160] if userinfo['bio'] # fake field from another API call
    user_default
  end

  def sync(upload_url, iu, setting)
#    caption = iu.caption
#    caption = " " if caption.blank?
#    geocode = (iu.longitude && iu.latitude)? ", 'geocode':'#{iu.latitude} #{iu.longitude}'" : ""
#    body = "{'data':{'object':{ 'type':'note', 'content':'#{caption}', 'attachments':[{ 'type':'photo', 'links':{'enclosure':[{'href':'http://#{ENV['host']}#{iu.url}','type':'image/jpeg'}],'alternate':[{'href':'#{upload_url}','type':'text/html'}]} }] } #{geocode}}}"
#    access_token = OAuth::AccessToken.new(get_consumer, setting.get_token(@provider_id), setting.get_secret(@provider_id))
#    resp = access_token.post("https://www.googleapis.com/buzz/v1/activities/@me/@self?alt=json", body, {'Content-Type' => 'application/json'})
#    resp
  end


#----------

  def get_authorize_url(parameters = nil)
    callback=ERB::Util.url_encode(get_callback(parameters))
    scope = "https://www.googleapis.com/auth/plus.me https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile"
    url = "https://accounts.google.com/o/oauth2/auth?scope=#{scope}&response_type=code&client_id=#{@key}&redirect_uri=#{callback}"
    return url, nil
  end

  def accept(params, request)
    callback=ERB::Util.url_encode(get_callback("next=#{params[:next]}"))
    url = "/o/oauth2/token"
    ses = https("https://accounts.google.com")
    resp = ses.post(url,"client_id=#{@key}&client_secret=#{@secret}&redirect_uri=#{callback}&code=#{params[:code]}&grant_type=authorization_code")
    if resp.class == Net::HTTPOK
      ret = JSON.parse(resp.body)
      @access_token_str = ret['access_token'] # default is online access_token which will expires in 3920
#      err = get_user(@access_token_str)
    else
      # The user might have rejected this application. Or there was some other error during the request.
      err = resp.body
    end
    err
  end 

  def get_user(access_token)
    ses = https(@api_site)
    resp = ses.get("/oauth2/v1/userinfo?access_token=#{access_token}")
    if resp.class == Net::HTTPOK
#puts "resp.body"
#puts resp.body
      @userinfo = JSON.parse(resp.body)
      @userinfo['bio'] = get_user_bio(ses, access_token)
      parse_user_id(@userinfo)
    else
      err = resp.body
    end
    err
  end

  def get_following_ids(user)
    ret = nil
#    resp = get_api_access_token(user).get("/buzz/v1/people/@me/@groups/@following?alt=json&prettyprint=true&max-results=#{FRIENDS_LIMIT}")
##puts resp
#    if resp.class == Net::HTTPOK
#      users = JSON.parse(resp.body)["data"]["entry"]
#      ret = users.collect {|u| u['id']}
#    end
    ret
  end

  def get_follower_ids(user)
    ret = nil
#    resp = get_api_access_token(user).get("/buzz/v1/people/@me/@groups/@followers?alt=json&prettyprint=true&max-results=#{FRIENDS_LIMIT}")
##puts resp
#    if resp.class == Net::HTTPOK
#      users = JSON.parse(resp.body)["data"]["entry"]
#      ret = users.collect {|u| u['id']}
#    end
    ret
  end
  
#--------------------------
protected
  
  def get_user_bio(ses, access_token)
    resp = ses.get("/plus/v1/people/me?access_token=#{access_token}")
    if resp.class == Net::HTTPOK
#puts "resp.body"
#puts resp.body
      userinfo = JSON.parse(resp.body)
      ret = userinfo['aboutMe']
    else
      ret = nil
    end
    ret
  end


end