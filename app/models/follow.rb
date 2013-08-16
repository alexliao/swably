class Follow < ActiveRecord::Base
  set_primary_key  "follow_id"
  belongs_to :user
  belongs_to :following, :class_name => 'User', :foreign_key => 'following_id'

  
  def feed_user(current_user)
    ret = {}
    ret[:type] = "follow"
    ret[:id] = self.follow_id
    ret[:created_at] = self.updated_at.to_i
    ret[:username] = self.user.username
    ret[:user_id] = self.user.id
    ret[:options] = {}
    options = ret[:options]
    options[:name] = self.user.display_name
    options[:user] = self.user.facade(current_user, :names_only => true)
    ret
  end

  def feed_following(current_user)
    ret = {}
    ret[:type] = "approval"
    ret[:id] = self.follow_id
    ret[:created_at] = self.updated_at.to_i
    ret[:username] = self.following.username
    ret[:user_id] = self.following.id
    ret[:options] = {}
    options = ret[:options]
    options[:name] = self.following.display_name
    options[:user] = self.following.facade(current_user, :names_only => true)
    ret
  end

  def self.add(user, following)
    Follow.delete_all("user_id = #{user.id} and following_id = #{following.id}")
    record = Follow.new(:user_id => user.id, :following_id => following.id)
    record.save
    user.followings_count(true)
    following.followers_count(true)
    record
  end

  def self.cancel(user, following)
    Follow.delete_all("user_id = #{user.id} and following_id = #{following.id}")
    user.followings_count(true)
    following.followers_count(true)
  end
  
  def self.refresh(user, following)
    connection.execute("update follows set updated_at = now() where user_id = #{user.id} and following_id = #{following.id}")
  end

  def self.followers_without_followings(user_id)
    "(select fr.user_id, follow_id, updated_at from follows fr left join (select following_id as u from follows where user_id=#{user_id}) fg on fr.user_id=fg.u where fr.following_id=#{user_id} and fg.u is null)"
  end
end
