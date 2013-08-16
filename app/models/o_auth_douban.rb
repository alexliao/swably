class OAuthDouban < OAuthProvider
  NAME = "豆瓣网"
  DISABLE_AUTO_FOLLOW = true  
  
  def initialize
    super
    @provider_id = "douban"
    @key = "0a527935f27b9ac31ef76ba1d772d049"
    @secret = "6234dd313cfd3861"
    @params = {:site => "http://www.douban.com", :scheme => :header, :http_method => :get, :realm=>"http://bannka.com", :request_token_path => "/service/auth/request_token", :access_token_path => "/service/auth/access_token", :authorize_path=> "/service/auth/authorize"}
    @api_site = "http://api.douban.com"
    @api_userinfo = '/people/%40me?alt=json&apikey='+@key
  end

  def parse_user_id(userinfo)
    @user_id = userinfo['db:uid']['$t'] if userinfo['db:uid']
    @username = userinfo['title']['$t'] if userinfo['title']
  end
   
  def get_user_url(user_id)
    ret = "http://www.douban.com/people/#{user_id}"
  end
   
  def parse_user_default(userinfo)
    user_default = {}
    user_default[:name] = userinfo['title']['$t'][0,20] if userinfo['title'] and userinfo['title']['$t']
    user_default[:bio] = userinfo['content']['$t'][0,160] if userinfo['content'] and userinfo['content']['$t']
#    user_default[:web] = get_user_url(userinfo['db:uid']['$t'])[0,100] if userinfo['db:uid'] and userinfo['db:uid']['$t']
    if userinfo['link']
      userinfo['link'].each do |link|
        user_default[:photo] = link['@href'][0,500] if link['@rel'] == 'icon'
        user_default[:web] = link['@href'][0,100] if link['@rel'] == 'homepage'
      end
    end
    user_default[:username] = user_default[:name].gsub(' ','')[0,20] if user_default[:name]
    user_default
  end

  def sync(upload_url, iu, setting)
    caption = iu.caption
    caption = "发布了新相片" if caption.blank?
    body = %Q{<?xml version='1.0' encoding='UTF-8'?>
      <entry xmlns:ns0="http://www.w3.org/2005/Atom" xmlns:db="http://www.douban.com/xmlns/">
        <content>#{caption} #{upload_url}</content>
      </entry>
    }
    @params[:site] = "http://api.douban.com"
    access_token = OAuth::AccessToken.new(get_consumer, setting.get_token(@provider_id), setting.get_secret(@provider_id))
    resp = access_token.post("/miniblog/saying", body, {'Content-Type' => 'application/atom+xml'})
    resp
  end


#----------
#  def get_authorize_url(parameters = nil)
#    callback = get_callback(parameters)
#    consumer = get_consumer
#    request_token = consumer.get_request_token(:oauth_callback => callback)
#    url = request_token.authorize_url + "&oauth_callback=#{callback}"
#    return url, {:token => request_token.token, :secret => request_token.secret}
#  end

  def authed(params)
#puts "authed?"
#puts params
    params[:oauth_token] #seems douban always return this param whatever user authorized or not
  end
  
  def get_userinfo
    # i should re-generate access_token proxy here, 
    # since ruby oauth library assume the domain of the auth site should be same with the resource site
    @params[:site] = "http://api.douban.com"
    @access_token = OAuth::AccessToken.new(get_consumer, @access_token.token, @access_token.secret)
    @access_token.get(@api_userinfo)
  end 

  def get_following_ids(user)
    ret = nil
    resp = get_api_access_token(user).get("/people/%40me/contacts?alt=json&max-results=#{FRIENDS_LIMIT}&apikey=#{@key}")
#puts resp
    if resp.class == Net::HTTPOK
      users = JSON.parse(resp.body)["entry"]
      ret = users.collect {|u| u['db:uid']['$t']}
    end
    ret
  end

# douban doesn't support this kind of API
#  def get_follower_ids(user)
#    ret = nil
#    resp = get_api_access_token(user).get("/people/%40me/rev_contacts?alt=json&max-results=#{FRIENDS_LIMIT}&apikey=#{@key}")
#puts resp
#    if resp.class == Net::HTTPOK
#      users = JSON.parse(resp.body)["entry"]
#      ret = users.collect {|u| u['db:uid']['$t']}
#    end
#    ret
#  end
  def get_follower_ids(user)
    nil
  end

end