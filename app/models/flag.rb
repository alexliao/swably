class Flag < ActiveRecord::Base
  self.primary_key =  "flag_id"
  belongs_to :user
  belongs_to :app

  def self.add(user, app)
    Flag.delete_all("user_id = #{user.id} and app_id = #{app.id}")
    record = Flag.new(:user_id => user.id, :app_id => app.id)
    record.save
    record
  end

  def self.cancel(user, app)
    Flag.delete_all("user_id = #{user.id} and app_id = #{app.id}")
  end
  
  def self.refresh(user, app)
    connection.execute("update flags set updated_at = now() where user_id = #{user.id} and app_id = #{app.id}")
  end

end
