class Notification < ActiveRecord::Base
  set_primary_key  "notification_id"
  belongs_to :user

  def self.add(user, comment)
    self.remove(user, comment)
    record = Notification.new(:user_id => user.id, :comment_id => comment.id)
    record.save
    record
  end

  def self.cancel(user, comment)
    self.remove(user, comment)
  end
  
protected

  def self.remove(user, comment)
    Notification.delete_all("user_id = #{user.id} and comment_id = #{comment.id}")
  end

end
