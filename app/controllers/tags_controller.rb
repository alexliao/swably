
class TagsController < ApplicationController
  before_filter :log_access
  #before_filter :log_online
  
  def apps
    # return unless validate_count
    return unless validate_id_and_get_tag
    limit = params[:count] || 100
    # @max_condition =  params[:max_id] ? "at.id < #{params[:max_id]}" : "true"
    @max_condition = "true"
    @apps = App.find :all, select: "count(at.app_id) as count, a.*, at.id as app_tag_id", joins: "a join app_tags at on a.id=at.app_id", conditions: ["#{@max_condition} and at.tag_id=?", params[:id]], group: "at.app_id", order: "count desc, at.id desc", limit: limit
    api_response @apps.facade, "apps"
  end

private
end

