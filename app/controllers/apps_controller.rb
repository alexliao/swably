class AppsController < ApplicationController
  include FileHelper
  #before_filter :redirect_anonymous
  before_filter :log_access
  
  #api
  def info
    return unless validate_format
    return unless validate_id_and_get_app
    api_response @app.facade(nil, :lang => session[:lang]), "app"
  end

  #api
  def status
    return unless validate_format
    app = App.find(:first, :conditions => ["package=? and signature=?", params[:package], params[:signature]])
    #app = App.new(:package => params[:package], :signature => params[:signature]) unless app
    if app
      #user = User.ensure(params[:imei], {:lang => params[:lang], :client_version => params[:client_version], :country_code => params[:country]})
      AppLocale.addUnlessNone(params[:lang], params[:country], app, params["name"], params["version_code"]) if params["name"]
      #Install.add(user, app)
    else
      app = App.new(:package => params[:package], :signature => params[:signature])
    end
#    app = App.create(:package => params[:package], :signature => params[:signature], :name => params[:name]) unless app
#    AppLocale.addUnlessNone(params[:lang], params[:country], app, params[:name])
#    user = User.ensure(params[:imei], {:lang => params[:lang], :client_version => params[:client_version], :country_code => params[:country]})
#    Install.addUnlessNone(user, app)
#    app.id = nil if app.apk.nil?
    api_response app.facade(nil, :lang => session[:lang]), "app"
  end
   

  #api
  # share the app which already in cloud, or return app with no id
  def share
    return unless validate_format
    return unless validate_signin
    app = App.find(:first, :conditions => ["package=? and signature=? and version_code >=?", params[:package], params[:signature], params[:version_code]])
    if app
      AppLocale.addUnlessNone(params[:lang], params[:country], app, params["name"], params["version_code"]) if params["name"]
      Share.add(@current_user, app)
    else
      app = App.new(:package => params[:package], :signature => params[:signature])
    end
    api_response app.facade(@current_user, :lang => session[:lang]), "app"
  end

  #api
  # upload and share an app which not in cloud yet.
  def upload
    # return unless validate_format
#    return unless validate_signin
    app = _add_app
    if app
#      AppLocale.remove(params[:lang], params[:country], app)
      AppLocale.addUnlessNone(params[:lang], params[:country], app, params[:name], params[:version_code])
      Share.add(@current_user, app)
      api_response app.facade(nil, :lang => session[:lang]), "app"
    else
      api_error api_errors2hash(@current_user.errors), 400
    end
  end

#  def status_list
#    _status_list
#    hash = {:user => @current_user, :apps => @cloud_apps}
#    api_response hash.facade
#  end
  
  def status_list
    _status_list
    api_response @cloud_apps.facade, "apps"
  end

  def _status_list
    return unless validate_format
#    return unless validate_signin
    @cloud_apps = []
    local_apps = JSON.parse(params[:apps])
    local_apps.each do |la|
      #app = @current_user.shared_apps.find(:first, :conditions => ["package=? and signature=?", la["package"], la["signature"]])
      app = App.find(:first, :conditions => ["package=? and signature=?", la["package"], la["signature"]])
      if app
        AppLocale.addUnlessNone(params[:lang], params[:country], app, la["name"], la["version_code"])
      end
      app ||= App.new(:package => la["package"], :signature => la["signature"])
      @cloud_apps << app
    end
  end

    
  def show
    @app = App.find(:first, :conditions => ["id=?", params[:id]])
    render :template => "apps/show#{session[:m]}"
  end  
  
#  #api
#  def remove
#    #user = User.find_by_imei(params[:imei])
#    user = User.ensure(params[:imei], {:lang => params[:lang], :client_version => params[:client_version], :country_code => params[:country]})
#    if params[:id]
#      app = App.find(params[:id])
#    else
#      app = App.find_by_package_and_signature(params[:package], params[:signature])
#    end
#    Install.remove(user, app)
#    render :nothing => true
#  end
  
  #api
  def liked_by_users
    return unless validate_format
    return unless validate_count
    return unless validate_id_and_get_app
    limit = params[:count]
    @max_condition =  params[:max_id] ? "like_id < #{params[:max_id]}" : "true"
    @users = @app.liked_by_users.find :all, :conditions => "#{@max_condition}", :order => "like_id desc", :limit => limit
    api_response @users.facade(@current_user), "users"
  end


  #api
  def trending
    return unless validate_format
    return unless validate_count
    limit = params[:count]
#    @max_condition =  params[:max_id] ? "like_id < #{params[:max_id]}" : "true"
    @apps = App.find_by_sql("select a.* from apps a join (select count(user_id) as c, app_id from (select distinct user_id, app_id from comments where created_at > subdate(now(), interval 2 day) ) c group by app_id order by c desc limit 10) c on a.id = c.app_id ")
    api_response @apps.facade(@current_user), "apps"
  end
  
  #api
  def shuffle
    return unless validate_format
    return unless validate_count
    limit = params[:count]
    range = App.count :conditions => 'reviews_count > 0'
    @apps = []
    limit.times do
      @apps << App.find(:first, :order => 'id', :conditions => 'reviews_count > 0', :offset => rand(range))
    end
    api_response @apps.facade(@current_user), "apps"
  end

  #api
  def uploaders
    return unless validate_format
    return unless validate_count
    return unless validate_id_and_get_app
    limit = params[:count]
    @max_condition =  params[:max_id] ? "share_id < #{params[:max_id]}" : "true"
    @users = @app.uploaders.find :all, :select => "users.*, shares.share_id, shares.updated_at as uploaded_at, shares.version_name", :conditions => "#{@max_condition}", :order => "share_id desc", :limit => limit
    api_response @users.facade, "users"
  end

  #api
  def all_comments
    return unless validate_format
    return unless validate_count
    return unless validate_id_and_get_app
    limit = params[:count]
    @max_condition =  params[:max_id] ? "id < #{params[:max_id]}" : "true"
    @comments = @app.comments.find :all, :conditions => "#{@max_condition}", :order => "id desc", :limit => limit
    ret = {:app => @app.facade(@current_user, :lang => session[:lang]), :reviews => @comments.facade(@current_user, :lang => session[:lang])}
    api_response ret
  end


  #api
  def find4claiming
    return unless validate_format
    return unless validate_signin
    @apps = App.find(:all, :conditions => ["signature=?", params[:signature]])
    api_response @apps.facade(@current_user), "apps"
  end

#  #api
#  def claim_signature
#    return unless validate_format
#    return unless validate_signin
#    UserSign.addUnlessNone(@current_user, params[:signature])
#    render :nothing => true
#  end

  #api
  def claim_apps_by_signature
    return unless validate_format
    return unless validate_signin
    UserSign.addUnlessNone(@current_user, params[:signature])
    @apps = App.find(:all, :conditions => ["signature=?", params[:signature]])
    @apps.each do |app|
      app.update_attribute :dev_id, @current_user.id    
    end
    @current_user.claims_count(true)
    render :nothing => true
  end

  #api
  def flag
    return unless validate_format
    return unless validate_signin
    return unless validate_id_and_get_app
    Flag.add(@current_user, @app)
    render :nothing => true
  end

  #api
  def update
    return unless validate_format
    return unless validate_signin
    return unless validate_id_and_get_app
    params[:app][:enabled] = true if params[:app][:dev_id] == ""
    if @current_user.id == @app.dev_id
      @app.update_attributes params[:app] 
      @current_user.claims_count(true)
    end
    api_response @app.facade(nil, :lang => session[:lang]), "app"
  end

  #api
  def following_using
    return unless validate_format
    return unless validate_count
    return unless validate_id_and_get_app
    limit = params[:count]
    @max_condition =  params[:max_id] ? "share_id < #{params[:max_id]}" : "true"
    #@users = @app.users.find :all, :conditions => "#{@max_condition}", :order => "share_id desc", :limit => limit
    @users = []
    api_response @users.facade, "users"
  end

  #api
  def following_comments
    return unless validate_format
    return unless validate_count
    return unless validate_id_and_get_app
    limit = params[:count]
    @max_condition =  params[:max_id] ? "id < #{params[:max_id]}" : "true"
    #@comments = @app.comments.find :all, :conditions => "#{@max_condition}", :order => "id desc", :limit => limit
    @comments = []
    api_response @comments.facade(@current_user, :lang => session[:lang]), "comments"
  end

  #api
  def find
    return unless validate_format
    return unless validate_count
    limit = params[:count]
    name = params[:name].strip
    name_like = "%#{params[:name].strip}%"
#    name_condition = "username like '#{name_like}' or name like '#{name_like}' or email like '#{name_like}'"
#    if params[:before]
#      before = Time.at(params[:before])
#      @users = User.find :all, :conditions => ["updated_at < ?", before], :order => "updated_at desc", :limit => limit
#    else
#      @users = User.find :all, :conditions => ["updated_at < ?", before], :order => "updated_at desc", :limit => limit
#    end
    #@users = User.find :all, :conditions => ["username = ?", name], :order => "updated_at desc", :limit => limit

#    locales = AppLocale.find :all, :select => 'distinct app_id', :conditions => ["name like ?", name_like], :limit => limit
#    @apps = []
#    if locales.size > 0
#      @apps = App.find :all, :conditions => "id in (#{locales.collect{|l| l.app_id}.join(',')})", :order => "updated_at desc"
#    end
#    @max_condition =  params[:max_id] ? "updated_at < date_add('1970-1-1', interval #{params[:max_id]} second)" : "true"
#    @apps = App.find :all, :select => 'distinct a.*', :joins => 'a join app_locales l on a.id = l.app_id', :conditions => ["l.name like ? and #{@max_condition}", name_like], :order => 'updated_at desc', :limit => limit 
    offset = params[:max_id] ? params[:max_id].to_i : 0
    @apps = App.find :all, :select => 'distinct a.*', :joins => 'a join app_locales l on a.id = l.app_id', :conditions => ["l.name like ?", name_like], :order => 'updated_at desc', :limit => limit, :offset => offset 
    
    i = 0
    @apps.each {|app| i += 1; app[:row] = offset + i}
    
    api_response @apps.facade(@current_user, :lang => session[:lang]), "apps"
  end

  # def download
  #   path = "public/apks/#{params[:folder]}/#{params[:filename]}"
  #   send_file path, :streaming => true
  # end

  def download
    return unless validate_id_and_get_app
    path = "public#{@app.apk}"
    send_file path, :streaming => true
    download = Download.new app_id: @app.id, user_id: params[:user_id], source: params[:r]
    download.save
  end

#-------------------------------------------------------------------------  
protected

  def _add_app
    begin
      infos = {:name => params[:name], :package => params[:package], :signature => params[:signature], :version_code => params[:version_code], :version_name => params[:version_name] }
      iu = save_app(params[:icon_file], params[:apk_file], infos)
      return iu
    rescue Exception => exc
      logger.error("#{Time.now.short_time} Custom log for apps/_add_app failed: " + exc.message)
      @current_user.errors.add :exception, exc.message
      return false
    end
  end

  def save_app(icon, apk, infos)
#    save_name = ((Time.now-Time.gm(2011))*1000).to_i.to_s
#    postfix = get_suffix(upload_field.original_filename)
#    postfix = sub_type(upload_field) if postfix == ''
#    #file_name = sanitize_filename(upload_field.original_filename).split('.')[0]
#    save_name = "#{save_name}.#{postfix}"
#    save_url = "#{url_dir}/#{save_name}"
#    save_path = "public#{save_url}"
##    if upload_field.methods.include?("local_path") and upload_field.local_path
##      #system "chmod", "644", upload_field.local_path
##      FileUtils.copy upload_field.local_path, save_path
##    else
#      File.open(save_path, "wb") { |f| f.write(upload_field.read) }
##    end
    
    #hashId = (infos[:package]+infos[:signature]).hash.to_s
    
    name = genApkName(infos[:package], infos[:signature])
    icon_url, icon_path = save_file(icon, get_picture_dir, name)
    apk_url, apk_path = save_file(apk, get_apk_dir, name)
    infos = infos.update({:icon=>icon_url, :apk => apk_url, :size=>File.size(apk_path)})

    app = App.find(:first, :conditions => ["package=? and signature=?", infos[:package], infos[:signature]])
    if app
      raise Exception.new("can not upload #{infos[:package]} v#{infos[:version_code]} which is not newer than existed v#{app.version_code}") if infos[:version_code].to_i <= app.version_code
      old_apk_path = "public#{app.apk}"
      old_icon_path = "public#{app.icon}"
      FileUtils.rm(old_apk_path, :force => true) if old_apk_path != apk_path
      FileUtils.rm(old_icon_path, :force => true) if old_icon_path != icon_path
      app.update_attributes(infos)
    else
      app = App.create(infos)
    end
    return app
  end
  
  def genApkName(package, signature)
    exist_count = App.count :conditions => ["package = ? and signature <> ?", package, signature]
    if exist_count == 0
      ret = package
    else
      ret = "#{package}.#{exist_count+1}"
    end
    ret
  end
  
end