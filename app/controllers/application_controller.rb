# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
# require 'lib/time_util'
# require 'lib/iconv_util'
# require 'gettext/rails'

class ApplicationController < ActionController::Base
  protect_from_forgery
  ADMIN_PASSWORD = "gaofei888"

  # init_gettext "main"
  before_filter :set_lang
  before_filter :set_code
  before_filter :set_mobile
  # before_filter :login_from_basic_auth
  # before_filter :login_from_user_key
  # before_filter :login_from_cookie
  # before_filter :login_from_param
  before_filter :login_by_user_id
  before_filter :set_current_user_for_template
  before_filter :set_lang
  before_filter :do_job
  #before_filter :set_back
  after_filter :log_action_duration
  #layout :enable_embed
  

  # def authorize
  #   flash[:admin_return] = request.path
  #   redirect_to :controller => "admin", :action => "login" unless (session[:is_admin] || (current_user and current_user.is_admin))
  # end

  def authorize
    flash[:admin_return] = request.path
    redirect_to :controller => "admin", :action => "login" unless (session[:is_admin] || (current_user and current_user.is_admin))
  end

  def login
    flash.keep :admin_return
    #for auto-login
    if params[:password] == ENV['admin_pwd']
        session[:is_admin] = true
        redirect_to :action => "index"
        return
    end    
    
    if request.get?
    else
      if params[:admin][:password] == ENV['admin_pwd']
        session[:is_admin] = true
        flash[:admin_return] ||= "/reports"
        redirect_to flash[:admin_return]
      else
        flash[:notice] = "Invalid password, try again\n"
      end
    end
  end


  #some backend job driven by access
  def do_job
# disable recycle invites
#    min = Time.now.min
#    #recycle invites 1 min per hour
#    if min == 0
#      ret = ActiveRecord::Base.connection.execute("delete from invites where invitee_id is null and created_at < subdate(now(), interval 3 day)") 
#      puts "recycle invites: #{ret}"
#    end
  end
  
  def set_mobile
    http_user_agent = request.env["HTTP_USER_AGENT"] || ""
#puts http_user_agent
    @guess_mobile = http_user_agent.downcase.include?("mobile")
    session[:m] = "_m" if params[:version] == 'm'
    session[:m] = "" if params[:version] == 'd'
    session[:m] = @guess_mobile ? "_m" : "" unless params[:version]
    #session[:m] = (http_user_agent.downcase.include?("android") or http_user_agent.downcase.include?("iphone")) ? "_m" : ""
    #session[:app_scheme] = params[:app_scheme] if params[:app_scheme]
  end

  def log_access
    @begin_time = Time.now
    #breakpoint()
  end
  
  def log_action_duration
    return unless @begin_time
    #breakpoint()

    @access.update_attribute(:duration, Time.now - @begin_time) if @access
    access = Access.new
    access.controller = request.path_parameters[:controller]
    access.action = request.path_parameters[:action]
    access.item_id = request.path_parameters[:id]
    access.method = request.method.to_s
    access.is_xhr = request.xhr?
    access.remote_ip = request.remote_ip
    access.http_user_agent = request.env["HTTP_USER_AGENT"]
    access.http_referer = gen_simple_referer(params)
    access.query_string = request.env["QUERY_STRING"]
    access.user_id = @current_user.id == 0 ? nil : @current_user.id
    access.imei = params[:imei]
    access.created_at = Time.now
    access.duration = Time.now - @begin_time 
    access.save
  end

  def gen_simple_referer(params)
    ret = params[:r] || params[:referer] || request.env["HTTP_REFERER"]
    if ret
      ret = "sync_sina" if ret.match('weibo\.') and controller='comments' and action='show'
      ret = "sync_tencent" if ret.match('t\.qq\.com') and controller='comments' and action='show'
    end
    ret 
  end

  def login_by_user_id
    if params[:user_id]
      user = User.find_by_id(params[:user_id])
      if user and user.enabled
        _sign_in(user)
      end
    end
  end

  def login_from_user_key
    if params[:user_id] and params[:user_key]
      if params[:official] == "197445" # for api call from official client
        user = User.find_by_id(params[:user_id])
      else
        user = User.find_by_id_and_password(params[:user_id], params[:user_key])
      end
      if user and user.enabled
        _sign_in(user)
#        if request.method == :get and !params[:embed]
#          params[:user_id] = nil
#          params[:user_key] = nil
#          params[:official] = nil
#          redirect_to params 
#        end
      end
    end
  end

  def login_from_basic_auth
    auth = request.env["HTTP_AUTHORIZATION"]
    if auth
      auth = auth.split
      if auth[0] == "Basic"
        name_password = request.decode64(auth[1]).split(":") # password can't contain ":" while username can
        name = name_password[0..-2].join(":")
        password = name_password[-1]
        logged_in_user = User.logon(name, password)
        if logged_in_user and logged_in_user.enabled
          _sign_in(logged_in_user)
        end
      end
    end
  end
  
  def login_from_cookie
    if session[:user_id].nil?
      if cookies[:auth_token]
        user = User.find_by_remember_token(cookies[:auth_token]) 
        if user && user.remember_token_expires && Time.now < user.remember_token_expires  and user.enabled
          _sign_in(user)
        else
          _sign_in(User.fake)
        end
      else
        _sign_in(User.fake)
      end
    end
  end

  def login_from_param
    if params[:current_user_id]
      user = User.find_by_id(params[:current_user_id]) 
      if user
        _sign_in(user)
      else
        _sign_in(User.fake)
      end
    end
  end

  def set_lang
#    session[:lang] = params[:lang] || cookies[:lang] || lang_by_request || ENV['lang']
#    session[:lang] = ENV['lang'] unless ['en', 'zh'].include? session[:lang]
    if(ENV['lang'] == 'zh') 
      session[:lang] = 'zh'
    else
      session[:lang] = params[:lang] || cookies[:lang] || lang_by_request || ENV['lang']
    end
#    session[:lang] = params[:lang] || ENV['lang']
    # set_locale session[:lang]
    I18n.locale = session[:lang]
    cookies[:lang] = { :value => session[:lang] , :expires => 1.years.from_now } if cookies[:lang] != session[:lang]
    #current_user.update_attribute(:lang, session[:lang]) if current_user.lang != session[:lang]
  end

  def set_code
    session[:code] = request.env["HTTP_ACCEPT_LANGUAGE"].gsub("-","_") if request.env["HTTP_ACCEPT_LANGUAGE"] #something like et,en-us;q=0.8,fa;q=0.6,it;q=0.4,fr;q=0.2
  end

  def set_back
    session[:back] = params[:back] || current_user.back || cookies[:back] || ENV['back']
    cookies[:back] = { :value => session[:back] , :expires => 1.years.from_now } if cookies[:back] != session[:back]
    current_user.update_attribute(:back, session[:back]) if current_user.back != session[:back]
  end

  def temp_user_locale(user)
    user = User.find(user) unless user.class == User
    old = GetText.locale
    set_locale user.lang
    yield
    set_locale old
  end
  
  def redirect_anonymous
    if current_user.is_anonymous
      if params[:format]
        api_error "unauthenticated user", 401
      else
        session[:request_uri] = request.env["REQUEST_URI"] unless request.xhr?
        redirect_to '/account/signin' 
      end
    end
  end
   
  def redirect_disabled
    if current_user and !current_user.activated
      redirect_to :controller => 'account', :action => 'disabled'
    end
  end

  def log_online
    return unless request.xhr? # change to log online from javascript
    Online.update(@current_user.id) unless @current_user.is_anonymous
  end
  
  def set_current_user_for_template
    @current_user = current_user
  end

#  def sync_current_user
#    session[:user_id] = @user.id
#  end
  
  def set_return_uri
    session[:original_uri] = request.request_uri unless params[:format]
  end
  
  def auto_login
    #auto sign in if the url is clicked from invite email
    if params[:login] != nil
      user = User.find_by_login_and_password(params[:login],params[:key])
      if user != nil
        _sign_in(user)
      end
    end
  end
  
#  def authorize
#    unless current_user
#      flash[:notice] = "请登录"
#      session[:original_uri] = request.request_uri
#      #flash[:autorun] = "login_button.click()"
#      #redirect_to :controller => 'welcome' and return false
#      redirect_to :controller => 'users', :action => 'login_form' and return false
#    end
#  end
  
  def redirect_to_homepage
    redirect_to("/welcome")
  end
  
  
#  def display_current_user
#    ret = current_user
#    if ret == nil
#      ret = User.new
#      ret.id = 0
#      ret.name = _("游客")
#    end
#    ret
#  end
  
  
#  def add_user_to_session_and_redirect_to_home(user)
#    _sign_in(user)
#    redirect_to_homepage
#  end
  
  def _sign_in(user)
    clear_match
    session[:user_id] = user["id"]
    @_current_user = nil
    set_current_user_for_template
#    #set default city
#    unless user.city or user.is_anonymous # this is expensive database query.
#      user.set_city_by_ip(request.remote_ip) 
#    end
    
#    if !user.is_anonymous and session[:invited_to_group_by]
#      invitor = User.find(session[:invited_to_group_by])
#      key = hash_group_id(@current_group.id)
#      temp_user_locale(user.id) do
#        msg = render_to_string :partial => 'messages/notification_invite_join_group', :locals => {:invitor => invitor, :invitee_id => user.id, :key => key}
#        create_notification(user.id, msg)
#      end
#    end
    #session[:original_uri] = @current_user.network_lack > 0 ? "/users/friends" : ''
  end
  
  #set default city
  def is_friend(user_id)
    if current_user == nil
      ret = false
    else
      ret = current_user.is_friend(user_id)
    end
    ret
  end
  
  
  def deliver_mail(mail) # work for only one receiver.
    #ret = deliver_as_gbk(mail)
    #ret = deliver(mail) if ret # try again with utf8
    ret = deliver(mail)
    ret
  end
 
  def send_email(from, to, subject, body, cc = nil, bcc = nil)
    deliver_mail(Mailer.create_simple_mail(from, to, subject, body, cc, bcc))
  end
  
#  def deliver_as_gbk(mail)
#    begin
#      deliver(IconvUtil.new.utf8_to_gbk_mail(mail))
#    rescue Exception => exc
#      logger.error("#{Time.now.short_time} Custom log for mail: Exception in ApplicationController::deliver_as_gbk: " + exc)
#      return exc.message
#    end
#  end
  
  #deliver mail, return nil if success, or error message
  def deliver(mail)
    begin
      mail.subject = "=?#{mail.charset}?b?#{Base64.encode64(mail.subject)}?="
      Mailer.deliver(mail)
      return nil
    rescue Exception => exc
      return exc.message
    end
  end

#  def self.deliver(mail)
#    begin
#      Mailer.deliver(mail)
#      return nil
#    rescue Exception => exc
#      return exc.message
#    end
#  end
  
  def error_color(text)
    "<font color=red>#{text}</font>"
  end
  
  def gbk_to_utf8(str)
    IconvUtil.new.gbk_to_utf8(str)
  end
    
 

  def expire_notify(user_id = nil)
    user_id ||= @current_user.id 
    begin
      expire_page(:controller => 'feeds', :action => 'check', :id => user_id)
    rescue
      puts e
    end
  end  
  
  def expire_notify_all()
    begin
      FileUtils.rm(Dir.glob('public/feeds/check/*.*'))
    rescue Exception => e
      puts e
    end
  end
  
#----------------------------------------------------------------
protected

  def current_user
    @_current_user = session[:user_id].to_i == 0 ? User.fake : User.find(session[:user_id]) unless @_current_user
    return @_current_user
  end

  def _login(user, remember_me = "1")
    _sign_in(user)
    # if remember_me == "1"
    #   current_user.remember_me
    #   cookies[:auth_token] = { :value => current_user.remember_token , :expires => current_user.remember_token_expires }
    # end
  end

  def offline(delay = nil)
    @current_user.offline(delay)
  end
 
  def logout
    # @current_user.forget_me unless @current_user.is_anonymous
    session[:user_id] = nil
    @current_user = User.fake
    cookies.delete :auth_token
  end

  # # not tested
  # def lang_by_client
  #   address = IpAddress.find_ip(request.remote_ip)
  #   ret = (address.province != '海外') ? 'zh' : 'en'  if address
  #   ret
  # end
  
  def lang_by_request
    str = (request.env["HTTP_ACCEPT_LANGUAGE"] || "").downcase
    str.match(/^zh/) ? "zh" : "en"
  end
  
  def __(str, b)
    eval %("#{str}"), b
  end

  def simple_format(original_value)
   	ret = render_to_string(:inline => "<%=simple_format(value)%>",  :locals => {:value => original_value || ''})
   	ret = ret[3..-5] if ret.match(/^<P>.*<\/P>$/im) # remove surrounding <p></p>
    ret || ''
  end
  def simple_format_ex(original_value)
   	render_to_string(:inline => "<%=simple_format_ex(value)%>",  :locals => {:value => original_value || ''})
  end

  def format_description(original_value)
    render_to_string(:inline => "<%=simple_format_ex(value)%>", :locals => {:value => original_value})
  end

  def verify_xhr()
    return request.xhr? # against hacker
  end

  def create_notification(to_id , content, read_at = nil)
    Notimsg.create(to_id, content, read_at)
    expire_notify(to_id) unless read_at
  end
  
#  def self.create_notification(to_id , content)
#    message = Notimsg.new(:from_id => 1, :to_id => to_id, :content => content) # temporily set id=1, because can't create ActionController instance
#    message.save      
#    expire_page("/messages/check/#{to_id}")
#  end

  def gen_notice(content, auto_fade = false)
    ret = "<span class='notice'>#{content}</span>"
    # remove auto fade feature for optimize javascript file size.
#    if auto_fade
#      id= "notice#{rand(10000)}"
#      ret = "<span id='#{id}'>#{ret}</span><script>new Effect.Fade($('#{id}'), { duration: 1, delay: 5 });</script>"
#    end
    ret
  end
  
  def self.convert(str)
    begin
      ret = IconvUtil.new.utf8_to_gbk(str)
    rescue
      ret = ''
    end  
    ret
  end
  
  def escape_string(str)
    render_to_string(:inline => "<%=escape_javascript(h(str))%>", :locals => {:str=>str})
  end

  # def format_geo(province, city, parts)
  #     parts = parts || ''
  #     parts = split_by_all_seperator(parts.gsub('.',' ').gsub('。',' ')).join(User::MATCH_SEP).strip
  #     sep = IpAddress::PROVINCE_LEVEL_CITY.include?(province) ? User::MATCH_SEP : User::GEO_SEP
  #     ret = "#{province}#{sep}#{city}#{User::MATCH_SEP}#{parts}"
  #     ret = compact_geo(ret)
  #     ret
  # end
  # def compact_geo(geo)
  #   ret = geo.split(User::MATCH_SEP).compact.join(User::MATCH_SEP) # remove reduntant MATCH_SEP, e.g. "北京    昌平" to "北京 昌平"
  #   ret = ret.sub(User::GEO_SEP+User::MATCH_SEP, User::GEO_SEP) # e.g. "海外@ 英国 伦敦" to "海外@英国 伦敦"
  #   ret = "" if ret == User::MATCH_SEP || ret == User::GEO_SEP
  #   ret
  # end
  
#  def notify_follow(user)
#    temp_user_locale(user) do
#      #_name = "<a href='/users/show/#{current_user.id}' target='_blank'>#{current_user.display_name}</a>"
#      _name = "<a href='/#{current_user.id}'>#{current_user.display_name}</a>"
#      msgstr = _('%s喜欢你了！你的魅力值增加了１')%_name
#      create_notification( user.id, msgstr)
#    end
#  end


protected
  def is_closed
    if session[:open]
      ret = false
    else
      @open_from = AppConfig.open_from_time(session[:lang])
      if @open_from.nil?
        ret = true
      else
        to = AppConfig.open_to_time(session[:lang])
        date = Time.local(@open_from.year,@open_from.month,@open_from.day)
        now = Time.now
        today = Time.local(now.year,now.month,now.day)
        @open_tf = Time.local(now.year,now.month,now.day,@open_from.hour,@open_from.min)
        @open_tt = Time.local(now.year,now.month,now.day,to.hour,to.min)
        @open_tt += 24*3600 if @open_tt <= @open_tf
        ret = (today >= date and Time.now >= @open_tf and Time.now <= @open_tt) ? false : true
        #calculate countdown time
        if ret
        #puts @open_from.hour
        #puts @open_tf
        #puts now
        #puts @open_tf - now
          @countdown_secs = (@open_from - now).to_i
          @countdown_secs = (@open_tf - now).to_i if @countdown_secs < 0
        end
      end
    end
    ret
  end

  #for API
  def api_response(facade, root = nil, code = 200)
    if params[:format] == 'xml'
      @headers['Content-Type'] = 'text/xml;'
      if root
        render :text => facade.to_xml(:root => root), :status => code
      else
        render :text => facade.to_xml, :status => code
      end
    elsif params[:format] == 'json'
      render :text => facade.to_json, :status => code
    end
  end
  
  def api_error(msg, code)
    ret = {:error_code => code, :error_message => msg}
    if params[:format] == 'xml'
      @headers['Content-Type'] = 'text/xml;'
      render :text => ret.to_xml(:root => "error"), :status => code
    elsif params[:format] == 'json'
      render :text => ret.to_json, :status => code
    else
      render :text => msg, :status => code
    end
  end
  
  def api_errors2hash(active_record_errors)
    errs = {}
    active_record_errors.each do |err|
      errs[err[0]] = err[1]
    end
    errs
  end
  
  def validate_signin
    if @current_user.is_anonymous
      api_error "The required parameters [user_id] and [user_key] doesn't match or missed.", 401
      return false
    else
      return true
    end
  end

  def validate_count
    if params[:count] and params[:count].to_i > 100
      api_error "The parameter [count] can not be more than 100.", 400
      return false
    else
      params[:count] = (params[:count] || 20).to_i
      return true
    end
  end

  def validate_format
    if params[:format].nil?
      api_error "you need to specify the return format, such as .xml", 400
      return false
    elsif ["xml", "json"].include?(params[:format])
      return true
    else
      api_error "Only format .xml and .json are supported for now.", 400
      return false
    end
  end

  def validate_source
    if params[:source_id]
      app = Client.find(:first, :conditions => "id=#{params[:source_id]} and app_key='#{params[:source_key] || ''}'")
      if app
        app.update_attribute(:enabled, 1) if app and app.enabled.nil?
      else
        api_error "[source_id] and [source_key] doesn't match.", 401
        return false
      end
    end
    return true
  end

  def validate_content
    if params[:content].nil?
      api_error "[content] can't be empty.", 400
      return false
    elsif params[:content].size > 240
      api_error "[content] can't be more than 240 characters.", 400
      return false
    end
    return true
  end
  
  def validate_presence_of_id
    ret = true
    unless params[:id]
      api_error "you need to specify [id].", 400
      ret = false
      return ret
    end
    ret
  end

  def validate_id_and_get_user
    ret = true
    if params[:id]
      @user = User.find_by_id params[:id]
    else
      api_error "you need to specify user [id].", 400
      ret = false
      return ret
    end
    unless @user
      api_error "ID [#{params[:id]}] doesn't exist", 404
      ret = false
    end
    ret
  end

  def validate_id_and_get_app
    ret = true
    if params[:id]
      @app = App.find_by_id params[:id]
    else
      api_error "you need to specify app [id].", 400
      ret = false
      return ret
    end
    unless @app
      api_error "ID [#{params[:id]}] doesn't exist", 404
      ret = false
    end
    ret
  end
  
  def validate_id_and_get_review
    ret = true
    if params[:id]
      @comment = Comment.find_by_id params[:id]
    else
      api_error "you need to specify review [id].", 400
      ret = false
      return ret
    end
    unless @comment
      api_error "ID [#{params[:id]}] doesn't exist", 404
      ret = false
    end
    ret
  end

  def validate_id_or_uid_and_get_entry
    ret = true
    if params[:id]
      @entry = Entry.find_by_id params[:id]
    elsif params[:uid]
      @entry = Entry.find_by_uid params[:uid]
    else
      api_error "you need to specify either [id] or [uid] for the entry.", 400
      ret = false
      return ret
    end
    unless @entry
      if params[:id]
        api_error "ID [#{params[:id]}] doesn't exist", 404 
      elsif params[:uid]
        api_error "UID [#{params[:uid]}] doesn't exist", 404
      end
      ret = false
    end
    ret
  end

  def after_reg(user)
    #_sign_in(user)
    _login(user)
    user = current_user
    if params[:follow]
      _u = User.find(params[:follow])
      user.follow(_u) unless _u.protected
      user.request(_u) if _u.protected
    end
    user.follow_official
#    if session[:connect_info]
#      user.connect(session[:connect_info])
      #user.sync_follower(session[:connect_info])
#      session[:connect_info] = nil
#    end
  end
  
  def genVipKey(min_id, count)
    User.hash_password("#{min_id},#{count}")
  end
  
  def matched_list
    session[:matched_list] ||= []
    session[:matched_list]
  end
  def get_current_match
    session[:current_match] ||= -1
    session[:current_match]
  end
  def set_current_match(value)
    session[:current_match] = value
  end
  def clear_match
    session[:matched_list] = nil
    session[:current_match] = nil
  end
  def push_to_matched_list(id)
    matched_list.delete id
    matched_list.push id
    set_current_match(matched_list.size-1)
  end

#  def render(options = nil, deprecated_status = nil, &block) #:doc:
#    raise DoubleRenderError, "Can only render or redirect once per action" if performed?
#    options ||= {}
#    if options[:nothing] == true
#      if options[:partial]
#        options[:partial] = "#{options[:partial]}#{session[:m]}"
#      else
#        template = options[:template] || default_template_name
#        layout = options[:layout] || "application"
#        options[:template] = "#{template}#{session[:m]}"
#        options[:layout] = "#{layout}#{session[:m]}"
#      end
#    end
#    super(options, deprecated_status, &block)
#  end  
  
  
#  def render_file(template_path, status = nil, use_full_path = false, locals = {}) #:nodoc:
#    template_path = "#{template_path}#{session[:m]}"
#    super(template_path, status, use_full_path, locals)
#  end

#  def render_partial(partial_path = default_template_name, object = nil, local_assigns = nil, status = nil) #:nodoc:
#    partial_path = "#{partial_path}#{session[:m]}"
#    super(partial_path, object, local_assigns, status)
#  end
  
  def mobile
    session[:m] == '_m'
  end
  
  def android
    http_user_agent = request.env["HTTP_USER_AGENT"] || ""
    http_user_agent.downcase.include?("android")
  end

  #def gen_stream_conditions(table_name = "v_updates")
  def gen_stream_conditions(table_name = "uploads")
    id_str = (table_name == "v_updates" ? "#{table_name}.post_id" : "#{table_name}.id")
    @order_by = params[:order_by] || (params[:date] ? "shot_at" : id_str)
    @before_date = params[:date]? "subdate(shot_at, interval 1 day) <= '#{params[:date]}'" : "true"
    if params[:max_id]
      if params[:order_by] == 'shot_at'
        upl = Upload.find(params[:max_id])
        @max_condition = "#{table_name}.shot_at < '#{upl.shot_at.short_time}'"
        @before_date = "true"
      else
        @max_condition =  "#{id_str} < #{params[:max_id]}"
      end
    else
      @max_condition = "true"
    end
  end

  def send_rss(collection, title = nil, description = nil, link = nil)
    url_params = params.clone
    url_params[:format] = nil
    feed = RSS::Maker.make("2.0") do |maker|
      maker.channel.title = title || @page_title + " - " + _('Bannka')
      maker.channel.description = description || ""
      maker.channel.link = link || url_for(url_params) #"http://#{HOST_NAME}"
      maker.items.do_sort = true
 
      collection.each do |item|
        rss_item = maker.items.new_item
        item.to_rss(rss_item)
      end
    end
    send_data feed.to_s, :type => "application/rss+xml", :disposition => 'inline'
  end
  
  # for embeded webpage in smartphone app
  def enable_embed
    session[:embed] = params[:embed] if params[:embed]
    if session[:embed]
      "embed"
    else
      "application"
    end
  end

end

  def gen_invite_code
#    invi = true
#    until not invi
##      code = rand(10000)
#      invi = Invite.find_by_invite_code(code)
#    end
#    code
    rand(100000000)
  end  
  

class Array
  def facade(current_user=nil, options = {})
    self.collect {|item| item.facade(current_user, options)}
  end
end

class Hash
  def facade(current_user=nil, options = {})
    ret = {}
    self.each {|key, value| ret[key] = value.methods.include?("facade") ? value.facade(current_user, options) : value}
    ret
  end
end

class Time
  
  def short_time
    strftime('%Y-%m-%d %H:%M:%S')
  end

end

