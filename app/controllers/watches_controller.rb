
class WatchesController < ApplicationController
  before_filter :log_access
  #before_filter :log_online
  
  #api
  def add
    return unless validate_format
    return unless validate_signin
    return unless validate_presence_of_id
    return unless validate_id_and_get_user
    comment = Comment.find_by_id params[:review_id]
    Watch.add(@user, comment)
    Mention.add(@current_user, @user)
    Notification.add(@user, comment)
    Feed.mention_review @user, @current_user, comment
    expire_notify(@user.id)
    api_response comment.facade, "review"
  end
  
  #api
  def cancel
    return unless validate_format
    return unless validate_signin
    return unless validate_id_and_get_user
    comment = Comment.find_by_id params[:review_id]
    Watch.cancel(@user, comment)
    api_response comment.facade, "review"
  end

private
end

