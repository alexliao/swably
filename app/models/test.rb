class Test < ActiveRecord::Base
  include CommonHelper

  def self.test_engage_dev
    app = App.find_by_id 13950
    reviews = Comment.find :all, :include => :user, :conditions => ["app_id = #{app.id} and comments.created_at > ?", Time.utc(0)], :order => "comments.id desc", :limit => Mailer::ENGAGE_REVIEW_LIMIT
    reviews.reverse!
    mail = Mailer.create_engage_dev("alex197445@gmail.com", reviews, app)
    puts mail
    Mailer.deliver(mail)
  end
end
