
class LikesController < ApplicationController
  before_filter :log_access
  #before_filter :log_online
  
  #api
  def add
    return unless validate_format
    return unless validate_signin
    return unless validate_presence_of_id
    app = App.find_by_id(params[:id])
    Like.add(@current_user, app)
    api_response app.facade(@current_user, :lang => session[:lang]), "app"
  end
  
  #api
  def cancel
    return unless validate_format
    return unless validate_signin
    return unless validate_presence_of_id
    app = App.find_by_id(params[:id])
    Like.cancel(@current_user, app)
    api_response app.facade(@current_user, :lang => session[:lang]), "app"
  end

private
end

