class Dig < ActiveRecord::Base
  set_primary_key  "dig_id"
  belongs_to :user
  belongs_to :review

  def self.add(user, comment)
    Dig.delete_all("user_id = #{user.id} and comment_id = #{comment.id}")
    record = Dig.new(:user_id => user.id, :comment_id => comment.id)
    record.save
    user.digs_count(true)
    comment.digs_count(true)
    record
  end

  def self.cancel(user, comment)
    Dig.delete_all("user_id = #{user.id} and comment_id = #{comment.id}")
    user.digs_count(true)
    comment.digs_count(true)
  end
  
  def self.refresh(user, comment)
    connection.execute("update digs set updated_at = now() where user_id = #{user.id} and comment_id = #{comment.id}")
  end

end
