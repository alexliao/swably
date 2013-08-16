class OAuthBuzz < OAuthProvider
  NAME = "Google Buzz"
  
  def initialize
    super
    @provider_id = "buzz"
    @key = "bannka.com"
    @secret = "Mn9oIF0tIyFdtOkO4aqAfo+Z"
    @params = {:site => "https://www.google.com", :request_token_path => "/accounts/OAuthGetRequestToken", :access_token_path => "/accounts/OAuthGetAccessToken", :authorize_path=> "/buzz/api/auth/OAuthAuthorizeToken"}
    @api_site = "https://www.googleapis.com"
    @api_userinfo = 'https://www.googleapis.com/buzz/v1/people/@me/@self?prettyprint=true&alt=json'
  end

  def parse_user_id(userinfo)
    @user_id = userinfo['data']['id']
    @username = userinfo['data']['displayName']
  end
   
  def get_user_url(user_id)
    ret = "http://www.google.com/profiles/#{user_id}"
  end
   
  def parse_user_default(userinfo)
    user_default = {}
    user_default[:name] = userinfo['data']['displayName'][0,20] if userinfo['data'] and userinfo['data']['displayName']
    user_default[:bio] = userinfo['data']['aboutMe'][0,160] if userinfo['data'] and userinfo['data']['aboutMe']
    #user_default[:web] = get_user_url(userinfo['data']['id'])[0,100] if userinfo['data'] and userinfo['data']['id']
    user_default[:photo] = userinfo['data']['thumbnailUrl'][0,500] if userinfo['data'] and userinfo['data']['thumbnailUrl']
    email = userinfo['data']['emails'][0]['value'] if userinfo['data'] and userinfo['data']['emails']
    user_default[:email] = email[0,100] if email
    user_default[:username] = email.split("@")[0][0,20] if email
    user_default
  end

  def sync(upload_url, iu, setting)
    caption = iu.caption
    caption = " " if caption.blank?
    geocode = (iu.longitude && iu.latitude)? ", 'geocode':'#{iu.latitude} #{iu.longitude}'" : ""
    body = "{'data':{'object':{ 'type':'note', 'content':'#{caption}', 'attachments':[{ 'type':'photo', 'links':{'enclosure':[{'href':'http://#{ENV['host']}#{iu.url}','type':'image/jpeg'}],'alternate':[{'href':'#{upload_url}','type':'text/html'}]} }] } #{geocode}}}"
    access_token = OAuth::AccessToken.new(get_consumer, setting.get_token(@provider_id), setting.get_secret(@provider_id))
    resp = access_token.post("https://www.googleapis.com/buzz/v1/activities/@me/@self?alt=json", body, {'Content-Type' => 'application/json'})
    resp
  end


#----------
  def get_authorize_url(parameters = nil)
    callback = get_callback(parameters)
    consumer = get_consumer
    request_token = consumer.get_request_token({:oauth_callback => callback},{:scope => "https://www.googleapis.com/auth/buzz"})
    url = request_token.authorize_url + "&scope=https://www.googleapis.com/auth/buzz&domain=bannka.com"
    return url, {:token => request_token.token, :secret => request_token.secret}
  end

  def get_following_ids(user)
    ret = nil
    resp = get_api_access_token(user).get("/buzz/v1/people/@me/@groups/@following?alt=json&prettyprint=true&max-results=#{FRIENDS_LIMIT}")
#puts resp
    if resp.class == Net::HTTPOK
      users = JSON.parse(resp.body)["data"]["entry"]
      ret = users.collect {|u| u['id']}
    end
    ret
  end

  def get_follower_ids(user)
    ret = nil
    resp = get_api_access_token(user).get("/buzz/v1/people/@me/@groups/@followers?alt=json&prettyprint=true&max-results=#{FRIENDS_LIMIT}")
#puts resp
    if resp.class == Net::HTTPOK
      users = JSON.parse(resp.body)["data"]["entry"]
      ret = users.collect {|u| u['id']}
    end
    ret
  end
  
end