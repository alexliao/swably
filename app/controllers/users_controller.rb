# require "lib/time_util"

class UsersController < ApplicationController
  #before_filter :redirect_anonymous, :except =>[:info, :show, :rss, :followings, :followers, :find]
  before_filter :log_access

  def rss
    @user = User.find(:first, :conditions => ["id=?", params[:id]])
    if !@user.protected
      @limit = 20
      @uploads = @user.uploads.find(:all, :include => [:user], :order => "uploads.id desc", :limit => @limit)
      send_rss(@uploads, "Bannka / #{@user.username}", "Bannka updates from #{@user.display_name} / #{@user.username}.")
    else
      render :text => _('This person has protected their updates.')
    end
  end
  
#   #api
#   def show
#     if params[:format]
#       return unless validate_format
#       return unless validate_count
#       return unless validate_id_and_get_user
#       @limit = params[:count]
#     else
#       @user = User.find(:first, :conditions => ["username=?", params[:username]]) if params[:username]
#       @user = User.find(:first, :conditions => ["id=?", params[:id]]) if params[:id]
#       @limit = mobile ? 10 : 20
#     end
#     #stream_id = params[:stream_id] || params[:user_id]
#     #if stream_id
#     #  @user = User.find(:first, :conditions => ["id=?", stream_id])
#     #else
#     #  @user = User.find(:first, :conditions => ["username=?", params[:id]])
#     #end
#     if @user
#       #@upload_pages = Paginator.new self, @user.uploads.count, limit, params[:page]
#       #@uploads = @user.uploads.find(:all, :include => [:user], :conditions => "#{@before_date} and #{@max_condition}", :order => "uploads.#{@order_by} desc", :limit => @limit)
# #      if params[:max_id]
# #        @uploads = @user.uploads.find(:all, :include => [:user], :conditions => "#{before_date} and uploads.id < #{params[:max_id]}", :order => "uploads.#{order_by} desc", :limit => limit)
# #      else
# #        @uploads = @user.uploads.find(:all, :include => [:user], :conditions => "#{before_date}", :order => "uploads.#{order_by} desc", :limit => @upload_pages.items_per_page, :offset => @upload_pages.current.offset)
# #      end
#       if @user.visible_to(@current_user)
#         if params[:order_by] == "shot_at" or params[:date]
#           gen_stream_conditions("uploads")
#           @uploads = @user.uploads.find(:all, :include => [:user], :conditions => "#{@before_date} and #{@max_condition}", :order => "uploads.#{@order_by} desc", :limit => @limit)
#           @days = Upload.find_by_sql("select count(*) as count, date(shot_at) as shot_at from uploads where user_id = #{@user.id} and shot_at is not null group by date(shot_at) order by shot_at desc limit 100")
#           @page_name = @user.username
#         else
#           gen_stream_conditions
#           #@uploads = @user.updates.find(:all, :include => [:user], :conditions => "#{@before_date} and #{@max_condition}", :order => "#{@order_by} desc", :limit => @limit)
#           @uploads = @user.uploads.find(:all, :include => [:user], :conditions => "#{@before_date} and #{@max_condition}", :order => "#{@order_by} desc", :limit => @limit)
#           @rss_enabled = true
#           @rss_url = "/users/rss/#{@user.id}"
#         end
#       end
#       if request.xhr?
#         render :partial => '/shared/updates', :locals => {:updates => @uploads, :init_script => false}
#       end
#       if params[:format]
#         code = @user.visible_to(@current_user) ? 200 : 403
#         if params[:user_info]
#           ret = Hash.new
#           ret[:user] = @user.facade(@current_user)
#           if @user.visible_to(@current_user)
#             ret[:updates] = @uploads.facade(@current_user)
#           end
#           api_response ret.facade, nil, code
#         else
#           if @user.visible_to(@current_user)
#             api_response @uploads.facade(@current_user), "update", code
#           else
#             api_error "The user is not visible", code
#           end
#         end
#       end
#     end
#   end

  # GET /users/1
  # GET /users/1.json
  def show
    @user = User.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user.facade}
    end
  end

  #api
  def following
    return unless validate_format
    return unless validate_count
    return unless validate_id_and_get_user
    limit = params[:count]
    @max_condition =  params[:max_id] ? "follow_id < #{params[:max_id]}" : "true"
    @users = @user.followings.find :all, :select => "users.*, follows.follow_id", :conditions => "#{@max_condition}", :order => "follow_id desc", :limit => limit
    ret = {:user => @user.facade(@current_user), :users => @users.facade(@current_user)}
    api_response ret
  end
  
  #api
  def followers
    return unless validate_format
    return unless validate_count
    return unless validate_id_and_get_user
    limit = params[:count]
    @max_condition =  params[:max_id] ? "follow_id < #{params[:max_id]}" : "true"
    @users = @user.followers.find :all, :select => "users.*, follows.follow_id", :conditions => "#{@max_condition}", :order => "follow_id desc", :limit => limit
    ret = {:user => @user.facade(@current_user), :users => @users.facade(@current_user)}
    api_response ret
  end

  #api
  def recommend
    return unless validate_format
    return unless validate_count
    limit = params[:count]
    ret = {:groups => {}}
# disable sns suggestions here
#    ENV['connections'].split.each do | provider_id |
#      if @current_user.setting.connected?(provider_id)
#        name = OAuthProvider.get_name(provider_id)
#        users = @current_user.sns_friends(provider_id)
#        if users.size > 0
#          ret[name] = users
#          ret[:groups][name] = users.size
#        end
#      end
#    end
    users = User.find_by_sql("select u.* from users u where u.enabled=1 and u.id <> #{@current_user.id} order by id desc limit #{limit}")
    ret["local"] = users
    ret[:groups]["local"] = users.size
    api_response ret.facade(@current_user)
  end

#  #api
#  def find
#    return unless validate_format
#    return unless validate_count
#    limit = params[:count]
#    name = params[:name].strip
#    name_like = "%#{params[:name].strip}%"
##    name_condition = "username like '#{name_like}' or name like '#{name_like}' or email like '#{name_like}'"
##    if params[:before]
##      before = Time.at(params[:before])
##      @users = User.find :all, :conditions => ["updated_at < ?", before], :order => "updated_at desc", :limit => limit
##    else
##      @users = User.find :all, :conditions => ["updated_at < ?", before], :order => "updated_at desc", :limit => limit
##    end
#    #@users = User.find :all, :conditions => ["username = ?", name], :order => "updated_at desc", :limit => limit
#    @users = User.find :all, :conditions => ["name = ?", name], :order => "updated_at desc", :limit => limit
#    #@users |= User.find :all, :conditions => ["email = ?", name], :order => "updated_at desc", :limit => limit
#    #@users |= User.find :all, :conditions => ["username like ?", name_like], :order => "updated_at desc", :limit => limit
#    @users |= User.find :all, :conditions => ["name like ?", name_like], :order => "updated_at desc", :limit => limit
#    #@users |= User.find :all, :conditions => ["email like ?", name_like], :order => "updated_at desc", :limit => limit
#    api_response @users.facade(@current_user), "users"
#  end


  #api
  def find
    return unless validate_format
    return unless validate_count
    limit = params[:count]
    name = params[:name].strip
    name_like = "%#{params[:name].strip}%"

    offset = params[:max_id] ? params[:max_id].to_i : 0
    @users = User.find :all, :conditions => ["name like ?", name_like], :order => 'length(name)', :limit => limit, :offset => offset 
    
    i = 0
    @users.each {|r| i += 1; r[:row] = offset + i}
    
    api_response @users.facade(@current_user, :lang => session[:lang]), "users"
  end


  #api
  def my_followings
    if params[:format]
      return unless validate_format
      return unless validate_signin
      return unless validate_count
      limit = params[:count]
    else
      limit = 20
    end
    @user_pages = Paginator.new self, @current_user.followings.size, limit, params[:page]
    @users = @current_user.followings.find :all, :order => "follow_id desc", :limit => @user_pages.items_per_page, :offset => @user_pages.current.offset
    if params[:format]
      api_response @users.facade(@current_user), "users"
    end
  end


#  #api
#  def my_followers
#    return unless validate_format
#    return unless validate_signin
#    return unless validate_count
#    limit = params[:count]
#    
#    if params[:without_followings] == 'true'
#      @online_users = User.find(:all, :joins => "u join onlines o on u.id = o.user_id join #{Follow.followers_without_followings(@current_user.id)} f on f.user_id = o.user_id", :conditions => ["u.enabled = 1 and o.online_at > subdate(now(), interval #{Online::ALIVE_SECONDS} second) "], :order => "online_at desc")
#      @friends = User.find(:all, :joins => "u join #{Follow.followers_without_followings(@current_user.id)} f on f.user_id = u.id", :conditions => ["u.enabled = 1"], :order => "f.updated_at desc", :limit => limit)
#    else
#      @online_users = User.find(:all, :joins => "u join onlines o on u.id = o.user_id join follows f on f.user_id = o.user_id", :conditions => ["u.enabled = 1 and f.following_id=#{@current_user.id} and o.online_at > subdate(now(), interval #{Online::ALIVE_SECONDS} second) "], :order => "online_at desc")
#      @friends = @current_user.followers.find :all, :order => "follows.updated_at desc", :limit => limit
#    end
#    @users = (@online_users | @friends)
#    api_response @users.facade(@current_user), "users"
#  end

  #api
  def my_followers
    if params[:format]
      return unless validate_format
      return unless validate_signin
      return unless validate_count
      limit = params[:count]
    else
      limit = 20
    end
    @user_pages = Paginator.new self, @current_user.followers.size, limit, params[:page]
    @users = @current_user.followers.find :all, :order => "follow_id desc", :limit => @user_pages.items_per_page, :offset => @user_pages.current.offset
    if params[:format]
      api_response @users.facade(@current_user), "users"
    end
  end

  #api
  def my_requesters
    if params[:format]
      return unless validate_format
      return unless validate_signin
      return unless validate_count
      limit = params[:count]
    else
      limit = 20
    end
    @user_pages = Paginator.new self, @current_user.requesters.size, limit, params[:page]
    @users = @current_user.requesters.find :all, :order => "requests.updated_at desc", :limit => @user_pages.items_per_page, :offset => @user_pages.current.offset
    if params[:format]
      api_response @users.facade(@current_user), "users"
    end
  end

  #api
  def blocklist
    if params[:format]
      return unless validate_format
      return unless validate_signin
      return unless validate_count
      limit = params[:count]
    else
      limit = 20
    end
    @user_pages = Paginator.new self, @current_user.badguys.size, limit, params[:page]
    @users = @current_user.badguys.find :all, :order => "blocks.updated_at desc", :limit => @user_pages.items_per_page, :offset => @user_pages.current.offset
    if params[:format]
      api_response @users.facade(@current_user), "users"
    end
  end

  #api
  def info
    return unless validate_format
    return unless validate_id_and_get_user
    if @current_user.id == @user.id
      api_response @user.facade(@current_user, :with_key => true), "user"
    else
      api_response @user.facade(@current_user), "user"
    end
  end

  #api
  def liked_apps
    return unless validate_format
    return unless validate_count
    return unless validate_id_and_get_user
    limit = params[:count]
    @max_condition =  params[:max_id] ? "like_id < #{params[:max_id]}" : "true"
    @apps = @user.liked_apps.find :all, :select => "apps.*, likes.like_id", :conditions => "#{@max_condition}", :order => "like_id desc", :limit => limit
    api_response @apps.facade(@current_user), "apps"
  end

  #api
  def uploadees
    return unless validate_format
    return unless validate_count
    return unless validate_id_and_get_user
    limit = params[:count]
    @max_condition =  params[:max_id] ? "apps.id < #{params[:max_id]}" : "true"
    @apps = @user.uploadees.find :all, :select => "apps.*, shares.share_id, shares.updated_at as uploaded_at", :conditions => "#{@max_condition}", :order => "share_id desc", :limit => limit
    api_response @apps.facade, "apps"
  end

  #api
  def claimed_apps
    return unless validate_format
    return unless validate_count
    return unless validate_id_and_get_user
#    limit = params[:count]
#    @max_condition =  params[:max_id] ? "apps.id < #{params[:max_id]}" : "true"
    @apps = @user.claimed_apps.find :all, :order => "apps.updated_at desc"
    api_response @apps.facade(@current_user), "apps"
  end

  #api
  def reviews
    return unless validate_format
    return unless validate_count
    return unless validate_id_and_get_user
    limit = params[:count]
    @max_condition =  params[:max_id] ? "comments.id < #{params[:max_id]}" : "true"
    @comments = @user.comments.find :all, :include => [:app, :user], :conditions => "#{@max_condition} and users.enabled=1", :order => "comments.id desc", :limit => limit
    ret = {:user => @user.facade(@current_user), :reviews => @comments.facade(@current_user, :lang => session[:lang])}
    api_response ret
  end

  #api
  def query
    return unless validate_format
    return unless validate_count
    _conditions = params[:conditions] || "true"
    map_field(_conditions)
    _order = params[:order] || "users.id desc"
    map_field(_order)
    _enabled_condition = User.enabled_condition
    params[:page] ||= 1
    #@user_pages = Paginator.new self, 1000, params[:count], params[:page]
    begin
      #@users = User.find :all, :conditions => "id > 9 and #{_enabled_condition} and #{_conditions}", :order => "#{_order}",  :limit => @user_pages.items_per_page, :offset => @user_pages.current.offset 
      @users = User.find :all, :conditions => "id > 9 and #{_enabled_condition} and #{_conditions}", :order => "#{_order}",  :limit => params[:count], :offset => params[:count].to_i*(params[:page].to_i-1) 
      api_response @users.facade(@current_user), "users"
    rescue Exception => e
      msg = e.to_s
      msg = msg.split(": SELECT ")[0]
      api_error msg , 400
    end
  end

  #api
  def count
    return unless validate_format
    _conditions = params[:conditions] || "true"
    map_field(_conditions)
    _enabled_condition = User.enabled_condition
    begin
      ret = User.count :all, :conditions => "id > 9 and #{_enabled_condition} and #{_conditions}" 
      hash = {:count => ret}
      api_response hash
    rescue Exception => e
      msg = e.to_s
      msg = msg.split(": SELECT ")[0]
      api_error msg , 400
    end
  end

  # PUT /users/1
  # PUT /users/1.json
  def update
    @user = User.find(params[:id])
    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to @user, notice: 'user was successfully updated.' }
        format.json { render json: @user.facade }
      else
        format.html { render action: "edit" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  #api
  def mentioned_friends
    if params[:format]
      return unless validate_format
      return unless validate_id_and_get_user
      limit = params[:count]
    end
    limit ||= 10

    gen_friends_for_mention(@user) if @user.mentioned_friends.count == 0
    # mentioned_friends = @user.mentioned_friends.find :all, order: "mention_id desc", limit: limit
    mentioned_friends = @user.mentioned_friends.find :all, \
      select: "users.*, if(w.user_id is null, false, true) as is_watching", \
      joins: "left join watches w on w.user_id=users.id and w.comment_id=#{params[:review_id]}", \
      order: "mention_id desc", limit: limit
    
    review = Comment.find_by_id params[:review_id]
    review_watchers = review.watchers.find :all, select: "users.*, true as is_watching", order: "watch_id desc", limit: limit*2
    # review_watchers = review.watchers.find :all, \
    #   select: "users.*, true as is_watching", \
    #   joins: "left join mentions m on m.friend_id=watches.user_id and m.user_id=#{@user.id}", \
    #   order: "watches.watch_id desc", limit: limit
    @users = mentioned_friends | review_watchers
    # @users = mentioned_friends 
    ret = {:user => @user.facade(@current_user), :users => @users.facade(@current_user, :names_only => true)}
    api_response ret
  end


  #----------------------------------------------------------------------
protected
  def map_field(str)
    #str.gsub!("users.nodes_count", "users.followings_count")
  end
  
  def gen_friends_for_mention(user)
    # followings = user.followings.find :order => "follow_id desc", :limit => 5
    recent_talkers = Comment.find_by_sql("select distinct user_id from comments order by id desc limit 5")
    recent_talkers.reverse.each do |r|
      friend = User.find_by_id r["user_id"]
      Mention.add(user, friend)
    end
  end
  #----------------------------------------------------------------------
private
  
end
