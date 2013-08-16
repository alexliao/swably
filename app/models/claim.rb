# This class is not used, because no related table in database
class Claim < ActiveRecord::Base
  set_primary_key  "claim_id"
  belongs_to :user
  belongs_to :app

  def self.add(user, app)
    record = Claim.new(:user_id => user.id, :app_id => app.id)
    record.save
    user.claims_count(true)
    record
  end

  def self.addUnlessNone(user, app)
    record = Claim.find(:first, :conditions => ["user_id = ? and app_id = ?", user.id, app.id])
    record = add(user, app) unless record
    record
  end

  def self.remove(user, app)
    Claim.delete_all("user_id = #{user.id} and app_id = #{app.id}")
    user.claims_count(true)
  end
  
  def self.remove_all(user)
    Claim.delete_all("user_id = #{user.id}")
    user.claims_count(true)
  end

  def self.refresh(user, app)
    connection.execute("update claims set updated_at = now() where user_id = #{user.id} and app_id = #{app.id}")
  end

end
