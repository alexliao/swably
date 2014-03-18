# require "lib/iconv_util"
class CommentsController < ApplicationController
  before_filter :log_access
  include CommonHelper
  include FileHelper

  #api
  def info
    return unless validate_format
    return unless validate_id_and_get_review
    api_response @comment.facade, "review"
  end
  
  #api
  def create
    return unless validate_format
    return unless validate_signin
    if params[:app_id].nil? or params[:app_id] == 0
      api_error "you need to specify app_id.", 400
      return
    end
    
    @comment = Comment.new()
    @comment.app_id = params[:app_id]
    @comment.content = truncate_ex(params[:content],120)
    @comment.in_reply_to_id = params[:in_reply_to_id].to_i if params[:in_reply_to_id] and params[:in_reply_to_id].to_i > 0
    @comment.user_id = @current_user.id
    @comment.model = params[:model].strip if params[:model]
    @comment.sdk = params[:sdk]
    @comment.image, @comment.image_size = save_image(params[:image]) if params[:image]
    
    posted = Comment.find(:first, :conditions => ["app_id = ? and user_id = ? and content = ? and created_at > subdate(now(), interval 1 day)", @comment.app_id, @comment.user_id, @comment.content])
    unless posted
      @comment.save
      posted = @comment
      @comment.update_parent
      @comment.clear_below_ids_for_above
      Watch.add(@current_user, @comment)
      @comment.notify_followers
      @comment.notify_watchers
      @current_user.sync(@comment, params[:sync_sns])
    end
    api_response posted.facade(nil, :lang => session[:lang]), "comment"
  end

  #api
  def delete
    if params[:format]
      return unless validate_format
      return unless validate_signin
      return unless validate_presence_of_id
    end
        
    @comment = Comment.find_by_id(params[:id])
    if @comment
      @comment.destroy
      @comment.update_parent
      @comment.clear_below_ids_for_above
      @comment.clear_above_ids_for_below
      if @comment.sns_id
        provider = OAuthProvider.get_instance(@comment.sns_id)
	    logger.info("#{Time.now.short_time} start delete #{@comment.sns_id} for review #{@comment.sns_status_id}")
        provider.delete(@comment.sns_status_id, @current_user.setting)
      end
      api_response @comment.facade, "review"
    else
      api_error "ID [#{params[:id]}] doesn't exist", 404
    end
  end 


  def list
    if params[:format]
      return unless validate_format
    end
    @limit = 10
    beforeCondition = params[:max_id]? "comments.id < #{params[:max_id]}" : "true"
    @comments = Comment.find(:all, :include => [:user], :conditions => "upload_id = #{params[:id]} and #{beforeCondition}", :order => 'comments.id desc', :limit => @limit)
    @comments.reverse!
    if params[:format]
      api_response @comments.facade(current_user), "comments"
    else
      render :partial => '/comments/list', :locals => {:comments => @comments, :update_id => params[:id], :is_owner => (Upload.find(params[:id]).user_id == @current_user.id)}
    end
  end

  #api
  def my_following
    return unless validate_format
    return unless validate_count
    return unless validate_signin
    limit = params[:count]
    @max_condition =  params[:max_id] ? "comments.id < #{params[:max_id]}" : "true"
#    @comments = Comment.find :all, :include => [:app, :user], :joins => "left outer join follows f on f.user_id=#{@current_user.id} and f.following_id=comments.user_id", :conditions => "(f.following_id is not null or (comments.user_id=#{@current_user.id} ) ) and #{@max_condition}", :order => "comments.id desc", :limit => limit
    @following = Comment.find :all, :include => [:app, :user], :joins => "join follows f on f.following_id = comments.user_id", :conditions => "f.user_id = #{@current_user.id} and #{@max_condition}", :order => "comments.id desc", :limit => limit
    @me = @current_user.comments.find :all, :include => [:app], :conditions => "#{@max_condition}", :order => "comments.id desc", :limit => limit
    @reply_me = Comment.find :all, :include => [:app, :user], :joins => "join comments c on c.id = comments.in_reply_to_id", :conditions => "c.user_id = #{@current_user.id} and #{@max_condition}", :order => "comments.id desc", :limit => limit
    @watching = @current_user.notified_comments.find :all, :include => [:app], :conditions => "#{@max_condition}", :order => "notifications.notification_id desc", :limit => limit
    @comments = @following | @me | @reply_me | @watching
    @comments.sort! { |a,b| b.id <=> a.id }
    api_response (@comments.uniq)[0,limit].facade(nil, :lang => session[:lang]), "reviews"
  end

  #api
  def following
    return unless validate_format
    return unless validate_count
    return unless validate_id_and_get_user
    limit = params[:count]
    @max_condition =  params[:max_id] ? "comments.id < #{params[:max_id]}" : "true"
    @comments = Comment.find :all, :include => [:app, :user], :joins => "join follows f on f.following_id = comments.user_id", :conditions => "f.user_id = #{@user.id} and #{@max_condition}", :order => "comments.id desc", :limit => limit
    api_response @comments.facade(@current_user, :lang => session[:lang]), "reviews"
  end

  #api
  def public
    return unless validate_format
    return unless validate_count
    limit = params[:count]
    @max_condition =  params[:max_id] ? "comments.id < #{params[:max_id]}" : "true"
    @comments = Comment.find :all, :include => [:app, :user], :conditions => "#{@max_condition} and users.enabled=1", :order => "comments.id desc", :limit => limit
    api_response @comments.facade(@current_user, :lang => session[:lang]), "reviews"
  end

  #api
  def requests
    return unless validate_format
    return unless validate_count
    limit = params[:count]
    @max_condition =  params[:max_id] ? "comments.id < #{params[:max_id]}" : "true"
    @comments = Comment.find :all, :include => [:app, :user], :conditions => "app_id=0 and in_reply_to_id is null and #{@max_condition} and users.enabled=1", :order => "comments.id desc", :limit => limit
    api_response @comments.facade(@current_user, :lang => session[:lang]), "reviews"
  end

  #api
  def shares
    return unless validate_format
    return unless validate_count
    limit = params[:count]
    @max_condition =  params[:max_id] ? "comments.id < #{params[:max_id]}" : "true"
    @comments = Comment.find :all, :include => [:app, :user], :conditions => "app_id > 0 and in_reply_to_id is null and #{@max_condition} and users.enabled=1", :order => "comments.id desc", :limit => limit
    api_response @comments.facade(@current_user, :lang => session[:lang]), "reviews"
  end

  def show
    @comment = Comment.find(:first, :conditions => ["id=?", params[:id]])
    render :template => "comments/show#{session[:m]}"
  end

  #api
  def above
    return unless validate_format
    return unless validate_count
    limit = params[:count]
    @comment = Comment.find(:first, :conditions => ["id=?", params[:id]])
    if @comment.above_ids.size > 0
      @reviews = Comment.find :all, :conditions => "id in (#{@comment.above_ids})", :order => "id desc", :limit => limit
      @reviews.reverse!
    else
      @reviews = []
    end
    api_response @reviews.facade(@current_user, :lang => session[:lang]), "reviews"
  end

  #api
  def below
    return unless validate_format
    return unless validate_count
    limit = params[:count]
    @comment = Comment.find(:first, :conditions => ["id=?", params[:id]])
    if @comment.below_ids.size > 0
      @reviews = Comment.find :all, :conditions => "id in (#{@comment.below_ids})", :order => "id", :limit => limit
    else
      @reviews = []
    end
    api_response @reviews.facade(@current_user, :lang => session[:lang]), "reviews"
  end

  #api
  def thread
    return unless validate_format
    return unless validate_count
    limit = params[:count]
    @comment = Comment.find(:first, :conditions => ["id=?", params[:id]])
    
    if @comment.above_ids.size > 0
      @above_reviews = Comment.find :all, :conditions => "id in (#{@comment.above_ids})", :order => "id desc", :limit => limit
      @above_reviews.reverse!
    else
      @above_reviews = []
    end

    if @comment.below_ids.size > 0
      @below_reviews = Comment.find :all, :conditions => "id in (#{@comment.below_ids})", :order => "id", :limit => limit
    else
      @below_reviews = []
    end

    @thread = @above_reviews.facade(@current_user, lang: session[:lang]) \
      + [@comment].facade(@current_user, lang: session[:lang], with_watchers: true) \
      + @below_reviews.facade(@current_user, lang: session[:lang])
    api_response @thread, "reviews"
  end

  #------------------------------------------------------------------------
  private
  
  def save_image(image)
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
    
    save_name = ((Time.now-Time.gm(2012))*1000).to_i.to_s
    image_url, image_path = save_file(image, get_picture_dir, save_name)
    image_size = File.size(image_path)

    return image_url, image_size
  end
  
  
end
