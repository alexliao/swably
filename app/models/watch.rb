class Watch < ActiveRecord::Base
  set_primary_key  "watch_id"
  belongs_to :user
  belongs_to :comment

  def self.add(user, comment)
    self.remove(user, comment)
    record = Watch.new(:user_id => user.id, :comment_id => comment.id)
    record.save
    user.watches_count(true)
    comment.watches_count(true)
    record
  end

  def self.cancel(user, comment)
    self.remove(user, comment)
    user.watches_count(true)
    comment.watches_count(true)
  end
  
protected

  def self.remove(user, comment)
    Watch.delete_all("user_id = #{user.id} and comment_id = #{comment.id}")
  end

end
