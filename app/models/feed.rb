class Feed < ActiveRecord::Base
  # attr_accessible :category, :lookups, :name, :param_default, :param_name, :sql
  OBJECT_USER = "user"
  OBJECT_REVIEW = "review"
  OBJECT_APP = "app"
  belongs_to :user
  belongs_to :producer, class_name: "User"

  def facade(current_user = nil, options = {})
    ret = {}
    ret[:id] = self.id
    ret[:title] = self.title
    ret[:content] = self.content if self.content # avoid literarl "null" 
    ret[:created_at] = self.created_at.to_i
    ret[:producer] = self.producer.facade(nil, options.merge(:names_only => true))
    ret[:object_type] = self.object_type
    ret[:object_id] = self.object_id
    ret[:read] = self.created_at.to_i < (options[:read_at].to_i || Time.now.to_i)
    ret
  end

	def self.follow(user, follower)
		feed = Feed.new
		feed.user_id = user.id
		feed.producer_id = follower.id
		feed.object_type = OBJECT_USER
		feed.object_id = follower.id
		feed.title = I18n.t(:feed_title_follow, locale: ENV['lang'])
		feed.save unless feed.exists
	end

	def self.following_add_review(user, review)
		feed = Feed.new
		feed.user_id = user.id
		feed.producer_id = review.user.id
		feed.object_type = OBJECT_REVIEW
		feed.object_id = review.id
		# feed.title = I18n.t(:feed_title_following_add_review, name: review.user.name)
		feed.title = I18n.t( (review.app_id.nil? or 0==review.app_id) ? :feed_title_following_add_request : :feed_title_following_add_review , locale: ENV['lang'] )
		feed.content = review.content
		feed.save unless feed.exists
	end

	def self.reply_my_review(user, review, my_review)
		feed = Feed.new
		feed.user_id = user.id
		feed.producer_id = review.user.id
		feed.object_type = OBJECT_REVIEW
		feed.object_id = review.id
		# feed.title = I18n.t(:feed_title_reply_my_review, name: review.user.name, my_review: my_review.content)
		feed.title = I18n.t(:feed_title_reply_my_review, my_review: my_review.content, locale: ENV['lang'])
		feed.content = review.content
		feed.save unless feed.exists
	end

	def self.mention_review(user, mentioner, review)
		feed = Feed.new
		feed.user_id = user.id
		feed.producer_id = mentioner.id
		feed.object_type = OBJECT_REVIEW
		feed.object_id = review.id
		feed.title = I18n.t(:feed_title_mention_review, name: review.user.name, locale: ENV['lang'])
		feed.content = review.content
		feed.save unless feed.exists
	end

	# def self.watching_add_reply(user, review, watching_review)
	# 	feed = Feed.new
	# 	feed.user_id = user.id
	# 	feed.producer_id = review.user.id
	# 	feed.object_type = OBJECT_REVIEW
	# 	feed.object_id = review.id
	# 	feed.title = I18n.t(:feed_title_watching_add_reply, name: review.user.name, watching_review: watching_review.content, locale: ENV['lang'])
	# 	feed.content = review.content
	# 	feed.save unless feed.exists
	# end

	def self.watching_add_reply(user, review)
		feed = Feed.new
		feed.user_id = user.id
		feed.producer_id = review.user.id
		feed.object_type = OBJECT_REVIEW
		feed.object_id = review.id
		# feed.title = I18n.t(:feed_title_watching_add_reply, name: review.user.name)
		feed.title = I18n.t(:feed_title_watching_add_reply, locale: ENV['lang'])
		feed.content = review.content
		feed.save unless feed.exists
	end

	def self.star_post(user, starrer, review)
		feed = Feed.new
		feed.user_id = user.id
		feed.producer_id = starrer.id
		feed.object_type = OBJECT_REVIEW
		feed.object_id = review.id
		feed.title = I18n.t(:feed_title_star_post, locale: ENV['lang'])
		feed.content = review.content
		feed.save unless feed.exists
	end

	def self.following_app_add_review(user, review)
		feed = Feed.new
		feed.user_id = user.id
		feed.producer_id = review.user.id
		feed.object_type = OBJECT_REVIEW
		feed.object_id = review.id
		feed.title = I18n.t(:feed_title_following_app_add_review, name: review.app.name, locale: ENV['lang'])
		feed.content = review.content
		feed.save unless feed.exists
	end

	def exists
		# count = Feed.count(conditions: ["user_id=? and producer_id=? and object_type=? and object_id=?", user_id, producer_id, object_type, object_id])
		latest = Feed.find :first, conditions: "user_id=#{self.user_id}", order: "id desc"
		return latest && latest.producer_id == self.producer_id && latest.object_type == self.object_type && latest.object_id == self.object_id;
	end

end
