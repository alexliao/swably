#require 'oauth/consumer'


class Setting < ActiveRecord::Base
  belongs_to :user

  def self.access_token_str(access_token)
    access_token.token+" "+access_token.secret
  end
  
  def get_token(provider_id)
    ret = nil
    if self["oauth_#{provider_id}"]
      ret = self["oauth_#{provider_id}"].split(' ')[0]
    end
    ret
  end
  def get_secret(provider_id)
    ret = nil
    if self["oauth_#{provider_id}"]
      ret = self["oauth_#{provider_id}"].split(' ')[1]
    end
    ret
  end

#  def set_options_provider(provider_id, user_id, username)
#    self["options_#{provider_id}"] = user_id + " " + username.gsub(" ", "%20")
#  end

  def user_id_provider(provider_id)
    ret = nil
    ret = user.options["#{provider_id}_user_id"]
    if ret.nil?
      if self["options_#{provider_id}"]
        ret = self["options_#{provider_id}"].split(' ')[0]
        user.options["#{provider_id}_user_id"] = ret
        user.save_options
      end
    end
    ret
  end

  def username_provider(provider_id)
    ret = nil
    ret = user.options["#{provider_id}_username"]
    if ret.nil?
      if self["options_#{provider_id}"]
        ret = self["options_#{provider_id}"].split(' ')[1]
        ret.gsub!('%20',' ')
        user.options["#{provider_id}_username"] = ret
        user.save_options
      end
    end
    ret
  end

#  def self.get_user_url(provider_id, user_id)
#    case provider_id
#    when "twitter"
#      ret = "http://twitter.com/#{user_id}"
#    when "facebook"
#      ret = "http://www.facebook.com/profile.php?id=#{user_id}"
#    when "google"
#      ret = "http://www.google.com/profiles/#{user_id}"
#    end
#    ret
#  end
  def connected?(provider_id)
    self["oauth_#{provider_id}"]
  end

  def connected_any?
    ret = 0
    ENV['connections'].split.each do | provider_id |
      ret += 1 if connected?(provider_id)
    end
    ret > 0
  end
  
  def connections
    ret = []
    ENV['connections'].split.each do | provider_id |
      ret << provider_id if connected?(provider_id)
    end
    ret.join(",")
  end
  
  def get_userlink(provider_id)
    provider = OAuthProvider.get_instance(provider_id)
    username = username_provider(provider_id)
    username = "@"+username if provider_id == 'twitter'
    "<a href='#{provider.get_user_url(user_id_provider(provider_id))}' target='_blank' class='outer'>#{username}</a>"
  end
  
#  def self.get_consumer(provider_id)
#    case provider_id
#    when "twitter"
#      consumer = OAuth::Consumer.new(get_oauth_key(provider_id), get_oauth_secret(provider_id), {:site => "http://api.twitter.com"})
#    when "facebook"
#      consumer = OAuth::Consumer.new(get_oauth_key(provider_id), get_oauth_secret(provider_id), {:site => "https://graph.facebook.com", :scheme => :query_string , :http_method => :get})
#    when "google"
#      consumer = OAuth::Consumer.new(get_oauth_key(provider_id), get_oauth_secret(provider_id), {:site => "https://www.google.com", :request_token_path => "/accounts/OAuthGetRequestToken", :access_token_path => "/accounts/OAuthGetAccessToken", :authorize_path=> "/buzz/api/auth/OAuthAuthorizeToken"})
#    end
#    consumer
#  end  

#  def self.get_oauth_key(provider_id)
#    case provider_id
#    when "twitter"
#      ret = "TRbBMyQj9IQ1sQwS5qXeHQ"
#    when "facebook"
#      ret = "111429088923989"
#    when "google"
#      ret = "bannka.com"
#    when "sina"
#      ret = "3481317456"
#    when "renren" # app id 122516
#      ret = "fae136074a05461db3c014bc4b961b31"
#    when "douban"
#      ret = "0a527935f27b9ac31ef76ba1d772d049"
#    end
#    ret
#  end
#  def self.get_oauth_secret(provider_id)
#    case provider_id
#    when "twitter"
#      ret = "fNDqE2R0d6hVCX5RkYrKkIlnYndR3nvdLZ4z43Af0g"
#    when "facebook"
#      ret = "d107be6c921f112a3683da94de1b4460"
#    when "google"
#      ret = "Mn9oIF0tIyFdtOkO4aqAfo+Z"
#    when "sina"
#      ret = "6bf4ce7d0fff9b4b29aac2e743d9d113"
#    when "renren"
#      ret = "ad5db4d389564e099f945152553def2a"
#    when "douban"
#      ret = "6234dd313cfd3861"
#    end
#    ret
#  end
  
#  def self.facebook_https
#    uri = URI.parse("https://graph.facebook.com/")
#    ses = Net::HTTP.new(uri.host, uri.port)
#    ses.use_ssl = true
#    ses.verify_mode = OpenSSL::SSL::VERIFY_NONE
#    ses
#  end
end
