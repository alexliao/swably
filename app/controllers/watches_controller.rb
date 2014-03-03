
class WatchesController < ApplicationController
  before_filter :log_access
  #before_filter :log_online
  
  #api
  def add
    return unless validate_format
    return unless validate_signin
    return unless validate_presence_of_id
    return unless validate_id_and_get_review
    user = User.find_by_id params[:user_id]
    Watch.add(user, @comment)
    api_response @comment.facade, "review"
  end
  
  #api
  def cancel
    return unless validate_format
    return unless validate_signin
    return unless validate_id_and_get_review
    user = User.find_by_id params[:user_id]
    Watch.cancel(user, @comment)
    api_response @comment.facade, "review"
  end

private
end

