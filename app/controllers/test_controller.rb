require 'yaml'
class TestController < ApplicationController
  include CommonHelper
  layout :nothing => true

  def engage_dev_email
    @app = App.find_by_id 316
    @reviews = Comment.find :all, :include => :user, :conditions => ["app_id = #{@app.id} and comments.created_at > ?", Time.utc(0)], :order => "comments.id desc", :limit => Mailer::ENGAGE_REVIEW_LIMIT
    @reviews.reverse!
    @email = "alex197445@gmail.com"
    render :template => "mailer/engage_dev"
  end
protected
  
end