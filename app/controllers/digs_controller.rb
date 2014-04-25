
class DigsController < ApplicationController
  before_filter :log_access
  #before_filter :log_online
  
  #api
  def add
    return unless validate_format
    return unless validate_signin
    return unless validate_presence_of_id
    return unless validate_id_and_get_review
    Dig.add(@current_user, @comment)
    Feed.star_post @comment.user, @current_user, @comment
    expire_notify @comment.user.id
    api_response @comment.facade, "review"
  end
  
  #api
  def cancel
    return unless validate_format
    return unless validate_signin
    return unless validate_id_and_get_review
    Dig.cancel(@current_user, @comment)
    api_response @comment.facade, "review"
  end

private
end

