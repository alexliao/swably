class UserSign < ActiveRecord::Base
  set_primary_key  "user_sign_id"
  belongs_to :user
  belongs_to :app

  def self.add(user, signature)
    record = UserSign.new(:user_id => user.id, :signature => signature)
    record.save
    record
  end

  def self.addUnlessNone(user, signature)
    record = UserSign.find(:first, :conditions => ["user_id = ? and signature = ?", user.id, signature])
    record = add(user, signature) unless record
    record
  end

  def self.remove(user, signature)
    UserSign.delete_all("user_id = #{user.id} and signature = #{signature}")
  end
  
  def self.remove_all(user)
    UserSign.delete_all("user_id = #{user.id}")
  end

  def self.refresh(user, signature)
    connection.execute("update user_signs set updated_at = now() where user_id = #{user.id} and signature = #{signature}")
  end

end
