class AppTag < ActiveRecord::Base
  belongs_to :app
  belongs_to :user
  belongs_to :tag

  def self.add(user, app, tag)
    record = AppTag.new(user_id: user.id, app_id: app.id, tag_id: tag.id)
    record.save
    record
  end

  # tag can be String tag name or Tag object
  def self.addOrUpdate(user, app, tag)
    if String == tag.class
      tag = Tag.ensure tag
    end

    record = AppTag.find(:first, :conditions => ["user_id = ? and app_id = ? and tag_id = ?", user.id, app.id, tag.id])
    unless record
      remove(user, app, tag)
      record = add(user, app, tag)
    end
    record
  end

  def self.remove(user, app, tag)
    AppLocale.delete_all("user_id = '#{user.id}' and app_id = #{app.id} and tag_id = #{tag.id}")
  end
  
end
