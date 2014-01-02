require 'oauth'  
require 'json'
class OAuth2Provider < OAuthProvider

  def authed(params)
    params[:code]
  end
   
   def access_token_str
    @access_token_str
  end

  def get_authorize_url(parameters = nil)
    callback=ERB::Util.url_encode(get_callback(parameters))
    url = "#{@api_site}#{@path_authorize}?client_id=#{@key}&response_type=code&redirect_uri=#{callback}"
    return url
  end

  def accept(params)
    callback=ERB::Util.url_encode(get_callback("next=#{params[:next]}"))
    ses = https(@api_site)
    resp = ses.post(@path_access_token,"client_id=#{@key}&client_secret=#{@secret}&redirect_uri=#{callback}&code=#{params[:code]}&grant_type=authorization_code")
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
  

end


