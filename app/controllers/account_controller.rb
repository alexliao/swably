require 'yaml'
class AccountController < ApplicationController
  include CommonHelper
  before_filter :redirect_anonymous, :only => [:sign_out, :invite_link]
  before_filter :log_access

  def dns
    return unless validate_format
    if ENV['lang'] == 'zh'
      ret = {:main => "117.121.10.138", :upload => "117.121.10.138"}
    else
     ret = {:main => "192.155.195.138", :upload => "192.155.195.138"}
    end
    api_response ret
  end

  
  #api
  def appversion
    app_version
  end
  def app_version
    return unless validate_format
    yml = YAML.load(File.open("app/views/account/app_changes_#{session[:lang]}.yml"))
#    yml = YAML.load(File.open("app/views/account/app_changes.yml"))
    changes = yml["changes"]
    ret = []
    old_version = params[:client_version] ? params[:client_version].to_i : 0 
    changes.each do |change|
      ret << change if change["code"] > old_version
    end 
    api_response ret
  end
  
  #api
  def upgrade
    yml = YAML.load(File.open("app/views/account/app_changes_#{session[:lang]}.yml"))
    changes = yml["changes"]
    # send_file "public/downloads/swably_#{session[:lang]}.data", :filename => "swably_#{session[:lang]}_#{Time.now.to_i}.apk", :streaming => true
    filename = "swably-#{session[:lang]}#{changes[0]["code"]}.apk"
    send_file "public/downloads/#{filename}", :streaming => true
  end
  
  #API
  def verifycredentials
    verify_credentials
  end
  def verify_credentials
    return unless validate_format
    @logged_in_user, @prompt = User.logon(params[:account], params[:password])
    if @logged_in_user
      facade = @logged_in_user.facade(@current_user)
      facade[:key] = @logged_in_user.password
      api_response facade, "user"
    else
      api_error @prompt, 401
    end
  end

  def signin
    enable_embed
    @page_title = _('Sign in')
    @user = User.new(params[:user])
    session[:return_url] = request.env["HTTP_REFERER"] if request.method == :get and request.env["HTTP_REFERER"] and request.env["HTTP_REFERER"].match(ENV['host'])
    if request.method == :post
      #params[:remember_me] = "1" if mobile #mobile is private, so remember me by default.
      logged_in_user, prompt = User.logon(params[:user][:username], params[:user][:plain_password])
      if logged_in_user
        _login(logged_in_user, params[:remember_me])
        redirect_to session[:return_url] || "/home"
      else
        flash.now[:notice] = "<div class='notice'>#{prompt}</div>" 
      end
    end
  end


  def signup
    enable_embed
    logout if params[:logout]
    @page_title = _('Sign up')
    params[:user] ||= {}
    @user = User.new(session[:user_default])
    if request.method == :post
      if params[:user][:plain_password].blank?
        @user.errors.add :plain_password, _('Password is required!')
      else
        @user.username = params[:user][:username]
        @user.plain_password = params[:user][:plain_password]
        @user.email = params[:user][:email]
        #@user.protected = params[:user][:protected]
        #@user.created_on_device = request.env["HTTP_USER_AGENT"]
        ret = User.create(@user)
        if ret
          next_step = session[:user_default] ? "/account/choose_phone" : "/account/profile"
          session[:user_default] = nil
          after_reg(@user)
          if session[:connect_info]
            @current_user.connect(session[:connect_info])
            #user.sync_follower(session[:connect_info])
            session[:connect_info] = nil
          end
          redirect_to next_step
          return
        end
      end
    end
  end

  #api
  def create
    return unless validate_format
        
    @user = User.new()
    @user.username = params[:username]
    @user.plain_password = params[:password]
    @user.email = params[:email]
    #@user.protected = params[:protected]
    if params[:password].blank?
      @user.errors.add :password, _('Password is required!')
    else
      #@user.created_on_device = request.env["HTTP_USER_AGENT"]
      ret = User.create(@user)
      if ret
        after_reg(@user)
        facade = @user.facade(@current_user)
        facade[:key] = @user.password
      end
    end
    if ret
      api_response facade, "user"
    else
      api_error api_errors2hash(@user.errors), 400
    end
  end

  def forget_password
    if request.xhr?
      email = params[:user][:email]
      users = User.find_all_by_email_and_enabled(email,1)
      if users.size > 0
        #reset_url = url_for(:host => ENV['host'], :only_path => false, :controller => "tools", :action => "password", :user_id => user.id, :user_key => user.password)
        err = deliver_mail(Mailer.create_reset_password(email, users))
        if err
          ret = error_color(_("Send unsuccessful. Please try later.")+"(#{err})")
        else
          ret = _('Password resetting-link has been sent to %s, please check your mailbox')%email
        end
      else
        ret = error_color(_('Email %s is not registered, please input another Email address')%email)
      end
      render :text => ret
   end
  end

  def deactivate
    @user = @current_user
    if request.method == :post
      @user.update_attribute(:enabled, false)
      sign_out
    end
  end
  
#  def signedin
#    if @current_user.is_anonymous
#      redirect_to "/" 
#      return
#    end
##    if session[:app_scheme]
##      @snap = "#{session[:app_scheme]}://#{ENV['host']}/signin?id=#{@current_user.id}&username=#{@current_user.username}&key=#{@current_user.password}"
##      session[:app_scheme] = nil
##      redirect_to @snap
##      return
##    end
#    @current_user.gen_thumbnails    
#    @signin = "nappstr://#{ENV['host']}/signin?id=#{@current_user.id}&username=#{@current_user.username}&key=#{@current_user.password}&avatar_mask=#{@current_user.display_photo.mask}&name=#{ERB::Util.url_encode(@current_user.display_name)}&bio=#{ERB::Util.url_encode(@current_user.bio)}"
#    redirect_to @signin
#  end

protected
  
end