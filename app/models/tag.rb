class Tag < ActiveRecord::Base

  def facade(current_user = nil, options = {})
    ret = {}
    ret[:id] = self.id
    ret[:name] = self.name
    ret[:created_at] = self.created_at.to_i
    if options[:app_id]
    	ret[:recent_users_json] = self.gen_recent_users_json options[:app_id] if options[:with_user_icons]
    	ret[:is_mine] = self.is_mine options[:app_id], current_user.id
    end
    ret
  end
	
	def self.ensure(name)
		tag = Tag.find_by_name name
		if nil == tag
			tag = Tag.new name: name
			tag.save
		end
		tag
	end

  # generate json for users thumbnails in tag list
  def gen_recent_users_json(app_id)
    limit = 3
    count = AppTag.count_by_sql "select count(*) from app_tags a where a.app_id=#{app_id} and a.tag_id=#{self.id}"
    users  = User.find_by_sql "select u.* from users u join app_tags a on a.user_id=u.id where a.app_id=#{app_id} and a.tag_id=#{self.id} order by a.created_at desc limit #{limit}"
    icons = users.collect {|user| user.display_photo.square}
    {count: count, icons: icons}.to_json
  end

  def is_mine(app_id, user_id)
  	ret = AppTag.find :first, conditions: "tag_id=#{self.id} and app_id=#{app_id} and user_id=#{user_id}"
  	ret ? true : false
  end

end
