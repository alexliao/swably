
class SharesController < ApplicationController
  before_filter :log_access
  #before_filter :log_online
  
  #api
  def my_following
    return unless validate_signin
    params[:id] = @current_user.id
    following
  end

  #api
  def following
    return unless validate_format
    return unless validate_count
    return unless validate_id_and_get_user
    limit = params[:count]
    @max_condition =  params[:max_id] ? "share_id < #{params[:max_id]}" : "true"
    @shares = Share.find :all, :include => [:app, :user], :joins => "join follows f on f.following_id = shares.user_id", :conditions => "f.user_id = #{@user.id} and #{@max_condition} and apps.id is not null", :order => "share_id desc", :limit => limit
    api_response @shares.facade, "shares"
  end
private
end

