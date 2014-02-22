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
      ret[:thumbnail] = Photo.new(self[:image]).tweet
    end
    ret[:below_json] = self.below_json
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

  def above_ids(refresh = false)
    ret = refresh ? nil : read_attribute("above_ids")
    unless ret
      ret = gen_above_id_array(self.id).join(",")
      self.update_attribute(:above_ids, ret)
    end
    ret
  end

  def below_ids(refresh = false)
    ret = refresh ? nil : read_attribute("below_ids")
    unless ret
      ret = gen_below_id_array(self.id).join(",")
      self.update_attribute(:below_ids, ret)
    end
    ret
  end

  def below_json(refresh = false)
    ret = refresh ? nil : read_attribute("below_json")
    unless ret
      ret = gen_below_json
      self.update_attribute(:below_json, ret)
    end
    ret
  end

  def clear_below_ids_for_above
    return if self.above_ids == ""
    Comment.connection.execute "update comments set below_ids = null, below_json = null where id in (#{self.above_ids})"
  end

  def clear_above_ids_for_below
    return if self.below_ids == ""
    Comment.connection.execute "update comments set above_ids = null where id in (#{self.below_ids})"
  end

  # def clear_below_json_for_above
  #   return if self.above_ids == ""
  #   Comment.connection.execute "update comments set below_json = null where id in (#{self.above_ids})"
  # end

  def gen_above_id_array(id)
    ret = []
    record = Comment.find :first, :select => "in_reply_to_id", :conditions => "id=#{id}"
    if record and record.in_reply_to_id
      ret << record.in_reply_to_id
      ret += gen_above_id_array(record.in_reply_to_id)
    end
    ret
  end

  def gen_below_id_array(id)
    ret = []
    direct_below_ids = Comment.find :all, :select => "id", :conditions => "in_reply_to_id = #{id}"
    direct_below_ids.each do |record|
      ret << record.id
      ret += gen_below_id_array(record.id)
    end
    ret
  end

  # generate json for reply thumbnails in post stream
  def gen_below_json
    return "" if self.below_ids.nil? or self.below_ids == ""
    below_array = below_ids.split(",").collect {|id| id.to_i}
    below_array.sort!
    below_array.reverse!
    ret = {app_icons: [], replies_count: below_array.size}
    (1..([below_array.size, 3].min)).each do |n|
      comment = Comment.find_by_id below_array[n-1]
      ret[:app_icons] << comment.app.display_icon.thumbnail
    end
    ret.to_json
  end

end
