class Mention < ActiveRecord::Base
  set_primary_key  "mention_id"
  belongs_to :user
  
  def self.add(user, friend)
    self.remove(user, friend)
    record = Mention.new(:user_id => user.id, :friend_id => friend.id)
    record.save
    record
  end

  def self.cancel(user, friend)
    self.remove(user, friend)
  end
  
protected

  def self.remove(user, friend)
    Mention.delete_all("user_id = #{user.id} and friend_id = #{friend.id}")
  end

end
