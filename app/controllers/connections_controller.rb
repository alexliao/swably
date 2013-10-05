#gem 'oauth'  
#require 'oauth/consumer'
require 'json'
require 'oauth'
require 'o_auth_provider.rb'
#require 'net/https'
#require 'net/http'

class ConnectionsController < ApplicationController
  #before_filter :redirect_anonymous, :except => [:signin, :accept]
  before_filter :log_access

  def index
  end
  
  def signin
    logout
    url = OAuthProvider.get_instance(params[:id]).get_authorize_url("next=signin")
    redirect_to url
  end
  
  def options
    @current_user.set_option_sync(params[:id], params[:option_sync] ? 1 : 0)
    @current_user.set_option_auto_follow(params[:id], params[:option_auto_follow] ? 1 : 0)
    @current_user.save_options
    flash["notice_#{params[:id]}"] = gen_notice(_("Saved"), true);
    redirect_to request.env["HTTP_REFERER"]
  end
  
#   def connect
#     url, session[:oauth_request] = OAuthProvider.get_instance(params[:id]).get_authorize_url("next=#{params[:next]}")
# puts "/connections/connect:"
# puts url
#     redirect_to url
#   end
  
  # def disconnect
  #   @current_user.setting.update_attribute("oauth_#{params[:id]}", nil)
  #   redirect_to request.env["HTTP_REFERER"]
  # end
  
#  # accept for web site
#  def accept
#    provider = OAuthProvider.get_instance(params[:id])
#    if provider.authed(params)
#      err = provider.accept(params, session[:oauth_request])
#      err = provider.get_user(provider.access_token_str)
#      unless err
#        connect_info = {:provider_id => params[:id], :access_token_str => provider.access_token_str, :user_id => provider.user_id, :username => provider.username}
#        do_connect(params[:id], connect_info, provider.user_default)
#        @next = gen_next_params(params[:next])
#      end
#      puts 
#      flash["notice_#{params[:id]}"] = err
#    else
#      flash["notice_#{params[:id]}"] = _("Authorization failed")
#    end
#    #redirect_to params[:next_step] || (session[:app_scheme] ? '/home' : '/connections' )
#    #redirect_to params[:next_step] || @signedin # for compatibility with opera mini browser which don't allow redirection
#    render :template => 'connections/accept_web'
#  end

  # for uniform OAuth in App
  def accept
    provider = OAuthProvider.get_instance(params[:id])
    if provider.authed(params)
      err = provider.accept(params)
    else
      err = _("Not authorized")
    end
    if err
      @err = err
    else
      @access_token = provider.access_token_str
    end
    render :layout => false
  end

  #api
  # for oauth in client app, such as facebook android SSO
  def accept_access_token
    provider = OAuthProvider.get_instance(params[:id])
    err = provider.get_user(params[:access_token])
    unless err
      connect_info = {:provider_id => params[:id], :access_token_str => params[:access_token], :user_id => provider.user_id, :username => provider.username}
      err = catch :new_user_try_signup_with_facebook_or_plus do
        do_connect(params[:id], connect_info, provider.user_default)
        @current_user.gen_thumbnails
        nil # clear err
      end
    end
    api_error(err, 400) if err
    api_response(@current_user.facade(nil, :with_key => true), "user") unless err
  end


  def find_friends
    #mark as activated to avoid guide process again
    @current_user.activated = true
    @current_user.save        

    users = @current_user.sns_friends_here(params[:id])
    users |= @current_user.invitors
    users |= @current_user.invitees
    if params[:contacts]
      emails = params[:contacts].split(",")
      emails.uniq!
      emails.compact!
#      emails.delete @current_user.email
      if emails.size > 0
        str = emails.collect{|email| "'"+email.gsub(/[^\w@.]/,"")+"'"}.join(",") # remove all none email character to avoid SQL error
        contacts = User.find :all, :conditions => "users.enabled=1 and users.email in (#{str})", :order => "users.created_at desc"
        users |= contacts 
      end    
    end
    users.delete @current_user
    api_response users.facade(@current_user), "users"
  end
  
  def invite_friends
    friends = @current_user.sns_friends_not_here(params[:id])
    api_response friends, "friends"
  end

#-------------------------------------------------------------------------  
protected
  def gen_next_params(action)
    @current_user.gen_thumbnails
    "nappstr://#{ENV['host']}/#{action}?id=#{@current_user.id}&username=#{@current_user.username}&key=#{@current_user.password}&avatar_mask=#{@current_user.display_photo.mask}&name=#{ERB::Util.url_encode(@current_user.display_name)}&bio=#{ERB::Util.url_encode(@current_user.bio)}&connections=#{@current_user.setting.connections}"
#    "swably://#{ENV['host']}/#{action}?id=#{@current_user.id}&username=#{@current_user.username}&key=#{@current_user.password}&avatar_mask=#{@current_user.display_photo.mask}&name=#{ERB::Util.url_encode(@current_user.display_name)}&bio=#{ERB::Util.url_encode(@current_user.bio)}&connections=#{@current_user.setting.connections}&signup_sns=#{@current_user.setting.signup_sns}"
  end

#  def find_user(provider_id, connect_info)
#    if provider_id == 'buzz'
#      ret = Setting.find(:first, :conditions => "oauth_buzz is not null and user_id_buzz = '#{connect_info[:user_id]}'")
#    else
#      ret = Setting.find(:first, :conditions => ["oauth_#{provider_id}=?", connect_info[:access_token_str]])
#    end
#    ret ? ret.user : nil
#  end
  
  def find_user(provider_id, connect_info)
    ret = Setting.find(:first, :conditions => "signup_sns = '#{provider_id}' and oauth_#{provider_id} is not null and user_id_#{provider_id} = '#{connect_info[:user_id]}'")
    ret ? ret.user : nil
  end

  def try_create_user(connect_info, user_default)
    user = User.new(user_default)
    user.username = connect_info[:username]
    #user.plain_password = "1234567890987654321"
    #user.created_on_device = request.env["HTTP_USER_AGENT"]
    ret = User.create(user)
    unless ret
      user.username = "#{connect_info[:provider_id]}_#{connect_info[:user_id]}"[0,20]
      ret = User.create(user)
    end
    ret
  end

  def do_connect(provider_id, connect_info, user_default)
#puts ":access_token_str: " + connect_info[:access_token_str]
    if @current_user.is_anonymous 
      user = find_user(provider_id, connect_info) 
      if user # sign in with sns
        user_default[:username] = user.username
        user.update_attributes(user_default)
        user.gen_thumbnails
        user.connect(connect_info)
        _login(user)
        #params[:next_step] = "/account/signedin/#{provider_id}"
      else # sign up with sns
        if ['facebook','plus'].include?(connect_info[:provider_id])
          throw :new_user_try_signup_with_facebook_or_plus, "This entry is not for new Swably user, please sign in with Twitter"
        end
        user = try_create_user(connect_info, user_default)
        if user
          user.connect(connect_info)
          user.setting.update_attribute(:signup_sns, provider_id)
          after_reg(user)
          #params[:next_step] = "/account/signedin/#{provider_id}"
        else
          session[:connect_info] = connect_info
          session[:user_default] = user_default
          params[:next_step] = "/account/signup?follow=#{params[:follow]}"
        end
      end
    end
#    @current_user.connect(connect_info) unless @current_user.is_anonymous
  end
  
end