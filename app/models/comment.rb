class Comment < ActiveRecord::Base
  include CommonHelper
  belongs_to :user
  belongs_to :app
  belongs_to :in_reply_to
  belongs_to :in_reply_to, :class_name => 'Comment', :foreign_key => 'in_reply_to_id'
  has_many :digs
  has_and_belongs_to_many :digged_by_users, :class_name => "User", :foreign_key => "comment_id", :association_foreign_key => "user_id", :join_table => "digs"
  
  def facade(current_user = nil, options = {})
    ret = {}
    ret[:id] = self.id
    ret[:content] = self.content
    if self.in_reply_to_id
      ret[:in_reply_to_id] = self.in_reply_to_id
      ret[:in_reply_to_user] = self.in_reply_to_user
    end
    ret[:created_at] = self.created_at.to_i
    ret[:user] = self.user.facade(nil, options.merge(:names_only => true))
#puts self.id if self.app == nil 
    ret[:app] = self.app.facade(nil, options.merge(:names_only => true)) if self.app # more robust in case data not consistence
    ret[:model] = self.model if self.model
    ret[:sdk] = self.sdk if self.sdk
    ret[:digs_count] = self.digs_count
    ret[:is_digged] = current_user.is_diging(self.id) ? true : false if current_user and !current_user.is_anonymous
    ret[:dig_id] = self[:dig_id] if self[:dig_id]
    if self[:image]
      ret[:image] = Photo.new(self[:image]).large
      ret[:thumbnail] = Photo.new(self[:image]).thumbnail
    end
    ret
  end
  

  def in_reply_to_user(refresh = false)
    ret = refresh ? nil : read_attribute("in_reply_to_user_json")
    unless ret
      if self.in_reply_to # maybe deleted
        ret = self.in_reply_to.user.facade(nil, :names_only => true).to_json
      else
        ret = "null"
      end
      rec = self
      rec = User.find_by_id self.id if rec.readonly? # sometimes the self record is readonly
      rec.update_attribute(:in_reply_to_user_json, ret)
    end
    ret
  end

  def notify_followers
    #Thread.new do
      users = self.user.followers
      users |= [self.in_reply_to.user] if self.in_reply_to
      users.each do |user|
        expire_notify(user.id) 
      end
    #end
  end
  
  def update_parent
      #comms = app.comments.find(:all, :include => [:user], :order => "comments.id desc", :limit => 10)
      #comms.reverse!
      #app.recent_comments = comms.facade(@current_user).to_json
      app.reviews_count(true) if app
      user.reviews_count(true) if user
      app.last_review(true) if app and self.in_reply_to_id == nil and self.content != ''
  end
  
   def digs_count(refresh = false)
    ret = refresh ? nil : read_attribute("digs_count")
    unless ret
      ret = self.digs(:refresh).count
      self.update_attribute(:digs_count, ret)
    end
    ret
  end

end
