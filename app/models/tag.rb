class Tag < ActiveRecord::Base

	def self.ensure(name)
		tag = Tag.find_by_name name
		if nil == tag
			tag = Tag.new name: name
			tag.save
		end
		tag
	end
end
