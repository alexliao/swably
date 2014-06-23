
class AppTagsController < ApplicationController
  before_filter :log_access
  #before_filter :log_online
  
  # POST /app_tags.json?user_id=xx&app_id=xx&tag_name=xx
  def create
    # @app_tag = AppTag.new(params[:app_tag])
    # @app_tag.tag_id ||= Tag.ensure(param[:tag_name])
    @app_tag = AppTag.addOrUpdate params[:user_id], params[:app_id], params[:tag_name]

    respond_to do |format|
      if @app_tag.save
        format.json { render json: @app_tag, status: :created, location: @app_tag }
      else
        format.json { render json: @app_tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /app_tags/1.json
  # DELETE /app_tags.json?user_id=xx&app_id=xx&tag_name=xx
  def destroy
    @app_tag = AppTag.where(user_id: params[:user_id], app_id: params[:app_id], tag_id: Tag.ensure(params[:tag_name]).id).first if params[:tag_name]
    # @app_tag = AppTag.where(user_id: params[:user_id], app_id: params[:app_id], tag_id: params[:tag_id]).first if params[:tag_id]
    @app_tag = AppTag.find(params[:id]) if params[:id]

    @app_tag.destroy

    respond_to do |format|
      format.json { head :no_content }
    end
  end


private
end

