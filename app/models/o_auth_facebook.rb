require 'oauth/signature/rsa/sha1'
require 'net/https'
require 'net/http'
class OAuthFacebook < OAuthProvider
  NAME = "Facebook"
  
  def initialize
    super
    @provider_id = "facebook"
    @key = "229666087090658"
    @secret = "b6f1f098c9eb2c5652a7eaeedd2b67a2"
    @params = {:site => "https://graph.facebook.com", :scheme => :query_string , :http_method => :get}
  end

  def parse_user_id(userinfo)
    @user_id = userinfo['id']
    @username = userinfo['name']
  end
   
  def get_user_url(user_id)
    ret = "http://www.facebook.com/profile.php?id=#{user_id}"
  end
   
  def parse_user_default(userinfo)
#puts userinfo.to_s
    user_default = {}
    user_default[:name] = userinfo['name'][0,20] if userinfo['name']
    user_default[:location] = userinfo['location']['name'][0,45] if userinfo['location'] and userinfo['location']['name']
    user_default[:bio] = userinfo['bio'][0,160] if userinfo['bio']
    user_default[:email] = userinfo['email'][0,100] if userinfo['email']
    #user_default[:web] = userinfo['link'][0,100] if userinfo['link']
    user_default[:web] = userinfo['website'][0,100] if userinfo['website']

    link = userinfo['link'] if userinfo['link']
    user_default[:username] = link.split('/')[-1][0,20] if link and link.split('/')[-1].size <= 20 # web maybe http://www.facebook.com/profile.php?id=100001842194356
    user_default[:username] ||= user_default[:name].gsub(" ","")[0,20] if user_default[:name]
    user_default[:username] ||= user_default[:email].split('@')[0][0,20] if user_default[:email]
    
    user_default[:photo] = userinfo['picture'][0,500] if userinfo['picture'] # it's pass through, not original
    user_default
  end

  def sync(upload_url, iu, setting)
    caption = "##{iu.app.name} #{iu.content} #{upload_url}"
    url = "/me/feed"
    data = "access_token=#{setting.oauth_facebook}&link=#{upload_url}&name=#{caption}"
    resp = facebook_https.post(url, data)
    resp
  end

  def delete(status_id, setting)
    return unless status_id
    url = "/#{status_id}?method=delete"
    data = "access_token=#{setting.oauth_facebook}"
    resp = facebook_https.post(url, data)
    resp
  end

#  def deleteRequest(request_id, setting)
#    url = "/#{request_id}_#{setting.user_id_facebook}?method=delete"
#    data = "access_token=#{setting.oauth_facebook}"
#    resp = facebook_https.post(url, data)
#    resp
#  end

#----------
  def get_authorize_url(parameters = nil)
    callback=ERB::Util.url_encode(get_callback(parameters))
    url = "https://graph.facebook.com/oauth/authorize?scope=offline_access,publish_stream,user_about_me,user_location,email,user_website&client_id=#{@key}&redirect_uri=#{callback}"
    return url, nil
  end

  def authed(params)
    params[:code]
  end

  def access_token_str
    @access_token_str
  end

#  def accept(params, request)
#    callback=ERB::Util.url_encode(get_callback("next=#{params[:next]}"))
##    callback=ERB::Util.url_encode(get_callback()+"?next=signin")
#    url = "/oauth/access_token?client_id=#{@key}&client_secret=#{@secret}&redirect_uri=#{callback}&code=#{params[:code]}"
#    ses = facebook_https
#    resp = ses.get(url)
#    if resp.class == Net::HTTPOK
#      @access_token_str = resp.body.split('=')[1]
#      resp = ses.get("/me?access_token=#{@access_token_str}")
#      if resp.class == Net::HTTPOK
#        @userinfo = JSON.parse(resp.body)
#        parse_user_id(@userinfo)
#        #prepare avatar
#        begin
#          resp = ses.get("/me/picture?type=large&access_token=#{@access_token_str}") # type can be square | small | normal | large 
#          if resp.code.to_i == 302
#            @userinfo['picture'] = resp['location'].sub("https", "http")
#          end
#        rescue
#        end
#      end
#    else
#      # The user might have rejected this application. Or there was some other error during the request.
#      err = resp.body
#    end
#    err
#  end 
  
  def accept(params, request)
    callback=ERB::Util.url_encode(get_callback("next=#{params[:next]}"))
#    callback=ERB::Util.url_encode(get_callback()+"?next=signin")
    url = "/oauth/access_token?client_id=#{@key}&client_secret=#{@secret}&redirect_uri=#{callback}&code=#{params[:code]}"
    ses = facebook_https
    resp = ses.get(url)
    if resp.class == Net::HTTPOK
      @access_token_str = resp.body.split('=')[1]
#      err = get_user(@access_token_str)
    else
      # The user might have rejected this application. Or there was some other error during the request.
      err = resp.body
    end
    err
  end 

  def get_user(access_token)
    ses = facebook_https
    resp = ses.get("/me?access_token=#{access_token}")
    if resp.class == Net::HTTPOK
      @userinfo = JSON.parse(resp.body)
      parse_user_id(@userinfo)
      #prepare avatar
      begin
        resp = ses.get("/me/picture?type=large&access_token=#{access_token}") # type can be square | small | normal | large 
        if resp.code.to_i == 302
          @userinfo['picture'] = resp['location'].sub("https", "http")
        end
      rescue
      end
    else
      err = resp.body
    end
    err
  end

  def get_following_ids(user)
    @friends = nil
    url = "/me/friends?fields=id&limit=500&access_token=#{user.setting.oauth_facebook}"
    resp = facebook_https.get(url)
puts resp
    if resp.class == Net::HTTPOK
      users = JSON.parse(resp.body)["data"]
      @friends = users.collect {|u| u['id']}
    end
    @friends
  end

  def get_follower_ids(user)
    @friends
  end

  #get friends and turns them to hash array
  def get_following(user)
    ret = []
    url = "/me/friends?fields=id,name,picture&limit=500&access_token=#{user.setting.oauth_facebook}"
    resp = facebook_https.get(url)
    if resp.class == Net::HTTPOK
      users = JSON.parse(resp.body)["data"]
      ret = users.collect{|u| {:name => u['name'], :avatar => u['picture'], :id => u['id']}}
    end
    ret
  end


#--------------------------
protected
  def facebook_https
    uri = URI.parse("https://graph.facebook.com/")
    ses = Net::HTTP.new(uri.host, uri.port)
    ses.use_ssl = true
    ses.verify_mode = OpenSSL::SSL::VERIFY_NONE
    ses
  end
  

end