class Like < ActiveRecord::Base
  set_primary_key  "like_id"
  belongs_to :user
  belongs_to :app

  def self.add(user, app)
    Like.delete_all("user_id = #{user.id} and app_id = #{app.id}")
    record = Like.new(:user_id => user.id, :app_id => app.id)
    record.save
    user.likes_count(true)
    app.likes_count(true)
    record
  end

  def self.cancel(user, app)
    Like.delete_all("user_id = #{user.id} and app_id = #{app.id}")
    user.likes_count(true)
    app.likes_count(true)
  end
  
  def self.refresh(user, app)
    connection.execute("update likes set updated_at = now() where user_id = #{user.id} and app_id = #{app.id}")
  end

end
