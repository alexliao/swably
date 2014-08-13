class AppTag < ActiveRecord::Base
  belongs_to :app
  belongs_to :user
  belongs_to :tag

  def facade(current_user = nil, options = {})
    ret = {}
    ret[:id] = self.id
    ret[:app] = self.app.facade(current_user, options)
    ret[:tag] = self.tag.facade(current_user, options)
    ret[:created_at] = self.created_at.to_i
    ret
  end

  def self.add(user_id, app_id, tag_id)
    record = AppTag.new(user_id: user_id, app_id: app_id, tag_id: tag_id)
    record.save
    record
  end

  # tag can be String tag name or Tag object
  def self.addOrUpdate(user_id, app_id, tag)
    if String == tag.class
      tag = Tag.ensure tag
    end

    # record = AppTag.find(:first, :conditions => ["user_id = ? and app_id = ? and tag_id = ?", user_id, app_id, tag.id])
    # unless record
    #   remove(user_id, app_id, tag.id)
    #   record = add(user_id, app_id, tag.id)
    # end
    remove(user_id, app_id, tag.id)
    record = add(user_id, app_id, tag.id)

    record
  end

  def self.remove(user_id, app_id, tag_id)
    AppTag.delete_all("user_id = '#{user_id}' and app_id = #{app_id} and tag_id = #{tag_id}")
  end
  
end
