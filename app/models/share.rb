class Share < ActiveRecord::Base
  set_primary_key  "share_id"
  belongs_to :user
  belongs_to :app

  def facade(current_user = nil, options = {})
    ret = {}
    ret[:id] = self.id
    ret[:created_at] = self.updated_at.to_i
    ret[:app] = self.app.facade
    ret[:user] = self.user.facade(nil, :names_only => true)
    ret[:version_name] = self.version_name
    ret
  end

  def self.add(user, app)
    # Share.delete_all("user_id = #{user.id} and app_id = #{app.id}")
    record = Share.new(:user_id => user.id, :app_id => app.id, :version_name => app.version_name)
    record.save
    user.shares_count(true)
    record
  end

#  def self.addUnlessNone(user, app)
#    record = Share.find(:first, :conditions => ["user_id = ? and app_id = ?", user.id, app.id])
#    record = add(user, app) unless record
#    record
#  end

  def self.remove(user, app)
    Share.delete_all("user_id = #{user.id} and app_id = #{app.id}")
    user.shares_count(true)
  end
  
  def self.remove_all(user)
    Share.delete_all("user_id = #{user.id}")
    user.shares_count(true)
  end

  def self.refresh(user, app)
    connection.execute("update shares set updated_at = now() where user_id = #{user.id} and app_id = #{app.id}")
  end

end
