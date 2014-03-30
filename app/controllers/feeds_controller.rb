class FeedsController < ApplicationController
  #before_filter :redirect_anonymous
  caches_page :check
  before_filter :log_access, :except => [:check]
  
  #api
  def check
    render :text => Time.now.to_f
  end
  
  def fetch2
    return unless validate_format
    return unless validate_signin
    return unless validate_count

    limit = params[:limit]
    since = params[:since] ? Time.at(params[:since].to_f) : Time.now - 3600*24*7

    count = @current_user.feeds.count(:conditions => ["created_at > ?", since])
    if 1 == count
      recent_feed = @current_user.feeds.find :first, order: "id desc"
    end
    if count > 1
      rows = @current_user.feeds.find(:all, :select => "u.name", :joins => "join users u on u.id=feeds.producer_id", :conditions => ["feeds.created_at > ?", since], :order => "feeds.created_at desc", :limit => limit)
      names = (rows.collect {|r| r["name"]}).uniq.join(", ")
    end

    ret = Hash.new
    ret[:fetch_time] = Time.now.to_f
    ret[:count] = count
    ret[:names] = names
    ret[:recent_feed] = recent_feed.facade if recent_feed
    api_response ret.facade
end

  def fetch
    return unless validate_format
    return unless validate_signin
    return unless validate_count

    limit = params[:limit]
    since = params[:since] ? Time.at(params[:since].to_f) : Time.now - 3600*24*30
    
    # following_reviews_count = Comment.count(:joins => "join follows f on f.user_id=#{@current_user.id} and f.following_id=comments.user_id", :conditions => ["comments.created_at > ?", since])
    # reply_me_reviews_count = Comment.count(:joins => "join comments c on c.user_id=#{@current_user.id} and c.id=comments.in_reply_to_id", :conditions => ["comments.created_at > ?", since])
    # watching_reviews_count = @current_user.notifications.count(:conditions => ["created_at > ?", since])
    # reviews_count = following_reviews_count + reply_me_reviews_count + watching_reviews_count
    # if reviews_count > 1
    #   rows = Comment.find(:all, :select => "u.name", :joins => "join users u on u.id=comments.user_id join follows f on f.user_id=#{@current_user.id} and f.following_id=comments.user_id", :conditions => ["comments.created_at > ?", since], :order => "comments.created_at desc", :limit => limit)
    #   review_names = (rows.collect {|r| r["name"]})
    #   rows = Comment.find(:all, :select => "u.name", :joins => "join users u on u.id=comments.user_id join comments c on c.user_id=#{@current_user.id} and c.id=comments.in_reply_to_id", :conditions => ["comments.created_at > ?", since], :order => "comments.created_at desc", :limit => limit)
    #   review_names |= (rows.collect {|r| r["name"]})
    #   rows = @current_user.notified_comments.find(:all, :select => "u.name", :joins => "join users u on u.id=comments.user_id", :conditions => ["notifications.created_at > ?", since], :order => "notifications.created_at desc", :limit => limit)
    #   review_names |= (rows.collect {|r| r["name"]})
    #   # reviews_count = review_names.size
    #   review_names = review_names.uniq.join(", ")
    # end
    # if reviews_count == 1
    #   if following_reviews_count == 1
    #     recent_review = Comment.find(:first, :select => "comments.*", :joins => "join follows f on f.user_id=#{@current_user.id} and f.following_id=comments.user_id", :order => "comments.created_at desc")
    #   elsif reply_me_reviews_count == 1
    #     recent_review = Comment.find(:first, :select => "comments.*", :joins => "join comments c on c.user_id=#{@current_user.id} and c.id=comments.in_reply_to_id", :order => "comments.created_at desc")
    #   elsif watching_reviews_count == 1
    #     recent_review = @current_user.notified_comments.find :first, :order => "notifications.created_at desc"
    #   end
    # end
    
    following_review_ids = Comment.find(:all, :select => "comments.id as id", :joins => "join follows f on f.user_id=#{@current_user.id} and f.following_id=comments.user_id", :conditions => ["comments.created_at > ?", since])
    reply_me_review_ids = Comment.find(:all, :select => "comments.id as id", :joins => "join comments c on c.user_id=#{@current_user.id} and c.id=comments.in_reply_to_id", :conditions => ["comments.created_at > ?", since])
    watching_review_ids = @current_user.notified_comments.find(:all, :select => "comments.id as id", :conditions => ["notifications.created_at > ?", since])
    review_ids = following_review_ids | reply_me_review_ids | watching_review_ids
    if review_ids.size > 1
      review_names = []
      if following_review_ids.size > 1
        rows = Comment.find(:all, :select => "u.name", :joins => "join users u on u.id=comments.user_id join follows f on f.user_id=#{@current_user.id} and f.following_id=comments.user_id", :conditions => ["comments.created_at > ?", since], :order => "comments.created_at desc", :limit => limit)
        review_names |= (rows.collect {|r| r["name"]})
      end
      if reply_me_review_ids.size > 1
        rows = Comment.find(:all, :select => "u.name", :joins => "join users u on u.id=comments.user_id join comments c on c.user_id=#{@current_user.id} and c.id=comments.in_reply_to_id", :conditions => ["comments.created_at > ?", since], :order => "comments.created_at desc", :limit => limit)
        review_names |= (rows.collect {|r| r["name"]})
      end
      if watching_review_ids.size > 1
        rows = @current_user.notified_comments.find(:all, :select => "u.name", :joins => "join users u on u.id=comments.user_id", :conditions => ["notifications.created_at > ?", since], :order => "notifications.created_at desc", :limit => limit)
        review_names |= (rows.collect {|r| r["name"]})
      end
      review_names = review_names.uniq.join(", ")
    end
    if review_ids.size == 1
      if following_review_ids.size == 1
        recent_review = Comment.find(:first, :select => "comments.*", :joins => "join follows f on f.user_id=#{@current_user.id} and f.following_id=comments.user_id", :order => "comments.created_at desc")
      elsif reply_me_review_ids.size == 1
        recent_review = Comment.find(:first, :select => "comments.*", :joins => "join comments c on c.user_id=#{@current_user.id} and c.id=comments.in_reply_to_id", :order => "comments.created_at desc")
      elsif watching_review_ids.size == 1
        recent_review = @current_user.notified_comments.find :first, :order => "notifications.created_at desc"
      end
    end

    follows_count = Follow.count :conditions => ["following_id = ? and follows.created_at > ?", @current_user.id, since]
    if follows_count == 1
      recent_follower = @current_user.followers.find(:first, :order => "follow_id desc")
    end
    follow_names = Follow.find :all, :select => "u.name", :joins => "join users u on u.id = user_id", :conditions => ["following_id = ? and follows.created_at > ?", @current_user.id, since], :order => "follows.created_at desc", :limit => limit
    follow_names = (follow_names.collect {|r| r["name"]}).uniq.join(", ")
    
    ret = Hash.new
    ret[:fetch_time] = Time.now.to_f
    ret[:reviews_count] = review_ids.size
    ret[:follows_count] = follows_count
    ret[:count] = ret[:reviews_count] + ret[:follows_count]
    ret[:review_names] = review_names
    ret[:follow_names] = follow_names
    ret[:recent_review] = recent_review.facade if recent_review
    ret[:recent_follower] = recent_follower.facade if recent_follower
puts "-------------"
puts ret.facade
    api_response ret.facade
  end

  #api
  def list
    return unless validate_format
    return unless validate_count
    return unless validate_signin
    limit = params[:count]
    @max_condition =  params[:max_id] ? "feeds.id < #{params[:max_id]}" : "true"
    @feeds = @current_user.feeds.find :all, :include => [:producer], :conditions => "#{@max_condition} and users.enabled=1", :order => "feeds.id desc", :limit => limit
    ret = {:user => @current_user.facade(@current_user), :feeds => @feeds.facade(@current_user, :lang => session[:lang])}
    api_response ret
  end
#-------------------------------------------------------------------------  
protected


end