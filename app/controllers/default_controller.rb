
class DefaultController < ApplicationController
#  include ActionView::Helpers::TextHelper
  before_filter :log_access
  

  def comeonin
    
#    @test = render_to_string :inline => "<%=simple_format(params[:content])%>"
  
#    @test = strip_tags "<div>abc<hello> 123</div><br/>"
  end
  
  def index

    if session[:m]
        @comments = Comment.find :all, :include => [:app, :user], :conditions => "in_reply_to_id is null and length(content) > 15 and length(content) < 90 and users.enabled=1", :order => "comments.id desc", :limit => 4
    end
    render :template => "default/index#{session[:m]}"
  end
  
end