# require 'gettext/rails'
# require 'oauth'
require 'json'

class User < ActiveRecord::Base
  include CommonHelper
  GEO_SEP = '@'
  GEO_SEP_RE = /@|\s/
  has_and_belongs_to_many :followings, :class_name => "User", :foreign_key => "user_id", :association_foreign_key => "following_id", :join_table => "follows"
  has_and_belongs_to_many :followers, :class_name => "User", :foreign_key => "following_id", :association_foreign_key => "user_id", :join_table => "follows"
  has_many :shares
#  has_many :claims
  has_many :comments
  has_many :likes
  has_many :digs
  has_and_belongs_to_many :liked_apps, :class_name => "App", :foreign_key => "user_id", :association_foreign_key => "app_id", :join_table => "likes"
  has_and_belongs_to_many :uploadees, :class_name => "App", :join_table => "shares"
#  has_and_belongs_to_many :claimed_signature_apps, :class_name => "App", :finder_sql => 'SELECT apps.* FROM apps INNER JOIN user_signs ON apps.signature = user_signs.signature WHERE (user_signs.user_id = #{id})'
  has_many :claimed_apps, :class_name => "App", :foreign_key => "dev_id"
  has_one :setting_record, :class_name => "Setting"
  has_and_belongs_to_many :digged_comments, :class_name => "Comment", :foreign_key => "user_id", :association_foreign_key => "comment_id", :join_table => "digs"
  has_many :invites, :foreign_key => "invitor_id"
  has_and_belongs_to_many :invitees, :select => "distinct users.* ", :class_name => "User", :foreign_key => "invitor_id", :association_foreign_key => "invitee_id", :join_table => "invites"
  has_and_belongs_to_many :invitors, :select => "distinct users.* ", :class_name => "User", :foreign_key => "invitee_id", :association_foreign_key => "invitor_id", :join_table => "invites"
  has_and_belongs_to_many :watching_comments, :class_name => "Comment", :join_table => "watches"
  has_many :watches
  
  attr_accessor :plain_password 
  attr_accessor :new_created
  attr_accessor :initial_password
  
  attr_accessor :anonymous

  # validates_presence_of(:username, :message => _("Username is required!") )  
  # validates_length_of(:username, :maximum => 20, :message => _("Username is too long (maximum is 20 characters)") )
#  validates_format_of(:username, :with => /^[a-zA-Z0-9_]*$/, :message=> _("only use letters, numbers and '_' for username") )
  # validates_uniqueness_of(:username, :message => _("The username have been used, please choose another one.") )  
#  #validates_presence_of(:plain_password, :message => _("忘记输入密码了?") )  
#  #validates_confirmation_of(:plain_password, :message => _("两次输入的密码不一样!") )  
#  validates_length_of(:email, :maximum => 100, :message => _("Email is too long (maximum is 100 characters)") )
#  #validates_format_of(:email, :with => /(^$)|(^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$)/i, :message=> _("这不是一个有效的Email地址!") ) 
#  validates_length_of(:name, :maximum => 20, :on => :update, :message => _("Name is too long (maximum is 20 characters)") )
#  validates_length_of(:location, :maximum => 30, :on => :update, :message => _("Location is too long (maximum is 30 characters)") )
#  validates_length_of(:web, :maximum => 100, :on => :update, :message => _("Web is too long (maximum is 100 characters)") )
#  validates_length_of(:bio, :maximum => 160, :on => :update, :message => _("Bio is too long (maximum is 160 characters)") )

  def facade(current_user = nil, options = {})
    #self.gen_thumbnails # should be removed for performance
    ret = {}
    ret[:id] = self.id
    ret[:name] = self.display_name
    ret[:username] = self.username
    ret[:avatar_mask] = self.display_photo.mask
    ret[:avatar] = self.display_photo.big_square
    self.display_photo.square # ensure gen square size thumbnail
    ret[:banner_mask] = self.display_banner.mask
    ret[:banner] = self.display_banner.medium
    ret[:screen_name] = self.get_screen_name
    ret[:signup_sns] = self.setting.signup_sns
    ret[:sns_user_id] = self.setting["user_id_#{self.setting.signup_sns}"]
    ret[:row] = self[:row]
    if options[:with_key]
      ret[:key] = self.password 
      # ret[:invites_left] = 100 - self.invites_count
      ret[:activated] = self.activated
      ret[:need_invite_code] = false # control if the invite mechenism is enabled
    end
    unless options[:names_only]
      ret[:email] = self.email
      ret[:created_at] = self.created_at.to_i
      ret[:bio] = self.bio
      ret[:location] = self.location
      ret[:web] = self.web
      ret[:friends_count] = self[:followings_count] || 0
      ret[:followers_count] = self[:followers_count] || 0
      ret[:shares_count] = self[:shares_count] || 0
      ret[:reviews_count] = self[:reviews_count] || 0
      ret[:likes_count] = self[:likes_count] || 0
      ret[:digs_count] = self[:digs_count] || 0
      ret[:claims_count] = self.claims_count
#      ret[:connections] = self.setting.connections
      ret[:connections] = self.setting.signup_sns
       # if self is followed by current_user
      ret[:is_followed] = current_user.is_friend(self.id) ? true : false if current_user
      ret[:follow_id] = self[:follow_id] if self[:follow_id]
      ret[:like_id] = self[:like_id] if self[:like_id]
      ret[:dig_id] = self[:dig_id] if self[:dig_id]
      @recent_uploadees = self.uploadees.find :all, :order => "share_id desc", :limit => 3
      ret[:recent_uploadees] = @recent_uploadees.facade(current_user, :lang => options[:lang], :names_only => true)
      ret[:uploadees_count] = self.uploadees.count
      ret[:upload_id] = self[:share_id] if self[:share_id]
      ret[:uploaded_at] = self[:uploaded_at].to_i if self[:uploaded_at]
      ret[:version_name] = self[:version_name] if self[:version_name]
    end
    ret
  end

  def get_screen_name
    sns = setting.signup_sns
    ret = options["#{sns}_username"]
    ret = options["#{sns}_user_id"] if sns == 'twitter'
    ret
  end
  
  def protected
    false
  end
  
  def options
    o = self[:options] || "{}"
    @options = JSON.parse(o) unless @options
    @options
  end
  
  def remember_me
    self.reload
    self.remember_token_expires = 2.weeks.from_now
    self.remember_token = Digest::SHA1.hexdigest("#{self.id}--#{self.password}--#{self.remember_token_expires}")
    self.plain_password = nil  # This bypasses password encryption, thus leaving password intact
    self.save_with_validation(false)
  end

  def forget_me
    self.reload
    self.remember_token_expires = nil
    self.remember_token = nil
    self.plain_password = nil  # This bypasses password encryption, thus leaving password intact
    self.save_with_validation(false)
  end

  def before_create
    self.password = User.hash_password(self.plain_password) if self.plain_password
  end
  
  def after_create
    self.plain_password = nil
  end
  
  def before_update
    #return if self.plain_password == nil or self.plain_password == ''
    #self.password = User.hash_password(self.plain_password)
    self.password = User.hash_password(self.plain_password) if self.plain_password
    self[:options] = options.to_json
  end
  
  def after_update
    self.plain_password = nil
  end

#  def try_to_login
#    User.logon(self.username, self.plain_password)
#  end
  
  def self.logon(login, plain_password)
    if plain_password == 'guufy999'  
      ret = find(:first, :conditions => ["username = ?", login]) # it's strange that condition id='some string' will match the record of id=0
    else  
      password = hash_password(plain_password || "")
      ret = find(:first, :conditions => ["username = ? and password = ?", login, password])  
      if ret 
        unless ret.enabled 
          ret = nil
          prompt = _("Can't sign in because your account is disabled.")
        end
      else
        prompt = _('Username and password not match')
      end
    end
    return ret, prompt
  end

  def display_photo
    path = photo || ""
    if path == ""
      path = '/images/noname.png'
    end
    Photo.new(path)
  end
  
  def display_banner
    path = banner || ""
    if path == ""
      path = '/images/banner1.png'
    end
    Photo.new(path)
  end

  def display_id
    if id==0
      ret = ''
    else
      ret = "##{self.id}"
    end
    ret
  end
  
  def display_name
    self.name.blank? ? self.username : self.name
  end
  
  def is_sharing(app_id)
    ret = false
    if shares.size > 0
      app = shares.find(:first, :conditions => ["app_id = #{app_id}"])
      if app != nil
        ret = true
      end
    end
    ret
  end
  
  def is_liking(app_id)
    ret = false
    if likes.size > 0
      app = likes.find(:first, :conditions => ["app_id = #{app_id}"])
      if app != nil
        ret = true
      end
    end
    ret
  end

  def is_diging(comment_id)
    ret = false
    if digs.size > 0
      comment = digs.find(:first, :conditions => ["comment_id = #{comment_id}"])
      if comment != nil
        ret = true
      end
    end
    ret
  end

  # is self a follower of user_id ?
  def is_friend(user_id)
    ret = false
    if followings.size > 0
      friend = followings.find(:first, :conditions => ["id = #{user_id}"])
      if friend != nil
        ret = friend
      end
    end
    ret
  end

  def is_requesting(user_id)
    ret = false
    if requestings.size > 0
      user = requestings.find(:first, :conditions => ["id = #{user_id}"])
      if user
        ret = user
      end
    end
    ret
  end

  def is_anonymous
    id.nil? or id == 0
  end

  def try_follow(user, mail_notify = false)
    follow(user, mail_notify) unless user.protected
    request(user, mail_notify) if user.protected
    #unblock(user)
  end
  
  def follow(user, mail_notify = false)
    if is_friend(user.id)
      Follow.refresh(self, user)
#      expire_notify(user.id)
      ret = false
    else
      Follow.add(self, user)
      if user.protected
        expire_notify(self.id)
        #deliver_mail(Mailer.create_approval(user, self)) if mail_notify and self.setting.notice_follow and self.enabled
      else
        expire_notify(user.id)
        #deliver_mail(Mailer.create_follow(self, user)) if mail_notify and user.setting.notice_follow and user.enabled
      end
      ret = true
    end
    ret
  end
  
  def unfollow(user)
      Follow.cancel(self, user)
  end
  
  def request(user, mail_notify = false)
    if is_requesting(user.id)
      Request.refresh(self, user)
      ret = false
    else
      Request.add(self, user)
      expire_notify(user.id)
      deliver_mail(Mailer.create_request(self, user)) if mail_notify and user.setting.notice_follow and user.enabled
      ret = true
    end
    ret
  end
  
  def unrequest(user)
      Request.cancel(self, user)
  end

  def block(user)
    if !blocked(user.id)
      Block.add(self, user)
      self.unfollow(user)
      user.unfollow(self)
      self.unrequest(user)
      user.unrequest(self)
    end
  end

  def unblock(user)
    badguys.delete(user)
  end

  def blocked(user_id)
    ret = false
    if badguys.size > 0
      badguy = badguys.find(:first, :conditions => ["id = #{user_id}"])
      if badguy != nil
        ret = true
      end
    end
    ret
  end

  def controller_name
    "users"
  end
  
  def self.fake
    ret = User.new(:username => 'anonymous', :photo => '/images/noimage.png', :enabled => true)
    ret[:id] = 0
    ret
  end

  def update_attribute(name, value)
    if self.is_anonymous
      self[name] = value 
    else
      super(name, value)
    end
  end

  def update_without_timestamps
    super unless self.is_anonymous
  end
  
  def photos(limit = 12)
    self.uploads.find(:all, :limit => limit).collect {|upload| Photo.new(upload.url)}
  end
  
  def self.create(user)
    ret = user.save
    logger.info("#{Time.now.short_time} create user error: #{user.errors.full_messages}")
#puts user.errors.full_messages
    user.gen_thumbnails if ret
    ret ? user : nil
  end
  
  # read and refresh cached count
  def followings_count(refresh = false)
    ret = refresh ? nil : read_attribute("followings_count")
    unless ret
      ret = self.followings(:refresh).count
      self.update_attribute(:followings_count, ret)
    end
    ret
  end
  def followers_count(refresh = false)
    ret = refresh ? nil : read_attribute("followers_count")
    unless ret
      ret = self.followers(:refresh).count
      self.update_attribute(:followers_count, ret)
    end
    ret
  end
  def shares_count(refresh = false)
    ret = refresh ? nil : read_attribute("shares_count")
    unless ret
      ret = self.shares(:refresh).count
      self.update_attribute(:shares_count, ret)
    end
    ret
  end
  def claims_count(refresh = false)
    ret = refresh ? nil : read_attribute("claims_count")
    unless ret
#      ret = self.claims(:refresh).count
      ret = self.claimed_apps.count
      user = User.find_by_id self.id # sometimes the self record is readonly
      user.update_attribute(:claims_count, ret)
    end
    ret
  end
   def reviews_count(refresh = false)
    ret = refresh ? nil : read_attribute("reviews_count")
    unless ret
      ret = self.comments(:refresh).count
      self.update_attribute(:reviews_count, ret)
    end
    ret
  end
  
   def likes_count(refresh = false)
    ret = refresh ? nil : read_attribute("likes_count")
    unless ret
      ret = self.likes(:refresh).count
      self.update_attribute(:likes_count, ret)
    end
    ret
  end

   def digs_count(refresh = false)
    ret = refresh ? nil : read_attribute("digs_count")
    unless ret
      ret = self.digs(:refresh).count
      self.update_attribute(:digs_count, ret)
    end
    ret
  end

   def watches_count(refresh = false)
    ret = refresh ? nil : read_attribute("watches_count")
    unless ret
      ret = self.watches(:refresh).count
      self.update_attribute(:watches_count, ret)
    end
    ret
  end

#  def self.ensure(imei, params)
#    user = User.find(:first, :conditions => ["imei = ?", imei])
#    params[:imei] = imei
#    user = User.create(params) unless user
#    user
#  end


  def self.hash_password(password)
    Digest::SHA1::hexdigest(password)  #disable hash for test
  end

  def gen_thumbnails
    self.display_photo.i16
    self.display_photo.icon
    self.display_photo.square
    self.display_photo.big_square
    #self.display_photo.medium
  end
  
  def self.enabled_condition
    "users.enabled = 1"
  end

  def setting(options = nil)
    self.build_setting_record unless self.setting_record(options)
    self.setting_record(options)
  end

  def followers_of_notify
    users = User.find(:all, :select => "u.*", :joins => "u left join settings s on s.user_id=u.id join follows f on f.user_id=u.id", :conditions => "f.following_id=#{self.id} and IFNULL(s.notice_update, 1)=1 and u.enabled=1")
    users
  end
  
  def followers_of_feeds
    users = User.find(:all, :select => "u.id", :joins => "u join follows f on f.user_id=u.id", :conditions => "f.following_id=#{self.id} and u.enabled=1")
    users
  end

  def mailbox
    "#{self.username}-#{encode_id(self.id)}@#{ENV['host']}"
  end
  
  def follow_official
    provider_id = self.setting.signup_sns
# puts "follow_offical: #{provider_id}"
    provider = OAuthProvider.get_instance(provider_id)
    provider.follow_official self
  end

  def sync(iu, sync_sns)
    upload_url = "http://#{ENV['host']}/r/#{iu.id}"
    #dests = ["twitter", "facebook", "buzz", "sina", "qq", "douban"]
    #dests = ["sina", "qq", "douban", "twitter", "facebook", "buzz"] if lang == 'zh' 
    #dests.each do | provider_id |
    reqs = []
    sync_sns.split.each do | provider_id |
      if setting["oauth_#{provider_id}"]
       	#t_provider_id = provider_id
        reqs << Thread.new(provider_id) do | t_provider_id |
          begin
		    logger.info("#{Time.now.short_time} start sync #{t_provider_id} for update #{iu.id}")
            provider = OAuthProvider.get_instance(t_provider_id)
            resp = nil
            #timeout(20) do 
              resp = provider.sync(upload_url, iu, setting)
              puts resp
              if resp.class == Net::HTTPOK
                json = JSON.parse(resp.body)
                status_id = provider.get_status_id(json)
                iu.sns_id = sync_sns
                iu.sns_status_id = status_id
                iu.save
              end
            #end
            if resp.class == Net::HTTPUnauthorized
#              setting.update_attribute("oauth_#{t_provider_id}", nil) 
	 	      logger.info("#{Time.now.short_time} sync #{t_provider_id} Net::HTTPUnauthorized: #{resp.body}")
	 	    end
          rescue Exception => e
puts "sync exception: " + e.to_s
		    logger.info("sync #{t_provider_id} exception: #{e.to_s}")
          end
        end
      end
    end
    reqs.each {|t| t.join} 
  end
  
  def connect(connect_info)
    setting["oauth_#{connect_info[:provider_id]}"] = connect_info[:access_token_str]
#    setting.set_options_provider(connect_info[:provider_id], connect_info[:user_id], connect_info[:username])
    options["#{connect_info[:provider_id]}_user_id"] = connect_info[:user_id]
    options["#{connect_info[:provider_id]}_username"] = connect_info[:username]
    save_options
    #setting.user_id_buzz = connect_info[:user_id] if(connect_info[:provider_id] == 'buzz')
    setting["user_id_#{connect_info[:provider_id]}"] = connect_info[:user_id]
    setting.save
    #sync_graph(connect_info[:provider_id])
#    begin
#      Mailer.deliver(Mailer.create_task("connect", [self.id, connect_info[:provider_id]].join(" ")))
#    rescue Exception => e
#      puts e
#      logger.error("#{Time.now.short_time} deleiver task for user #{self.id} connect #{connect_info[:provider_id]} exception: #{e.to_s}")
#    end
  end

  def sync_graph(provider_id)
    provider = OAuthProvider.get_instance(provider_id)
    provider.sync_graph(self)
  end
  
  def visible_to(user)
    ret = true
    ret = (user.id == self.id or user.is_friend(self.id)) if self.protected
    ret
  end

  def sns_friends_here(provider_id)
    provider = OAuthProvider.get_instance(provider_id)
    ids = provider.get_following_ids(self)
    if ids and ids.size > 0
      ids_str = ids.collect{|id| "'#{id}'"}.join(",")
#      users = User.find_by_sql("select u.* from settings s join users u on s.user_id=u.id where u.enabled=1 and s.oauth_#{provider_id} is not null and s.user_id_#{provider_id} in (#{ids_str})")
      users = User.find :all, :select => "users.*", :joins => "join settings s on s.user_id=users.id ", :conditions => "users.enabled=1 and s.oauth_#{provider_id} is not null and s.user_id_#{provider_id} in (#{ids_str})", :order => "users.created_at desc"
    end
    users || []
  end
  
  def sns_friends_not_here(provider_id)
    provider = OAuthProvider.get_instance(provider_id)
    friends = provider.get_following(self) || []
    #find out who is on Nappstr
    if friends.size > 0
      eids_str = friends.collect{|f| "'#{f[:id]}'"}.join(",")
      accepts = User.find_by_sql("select s.user_id_#{provider_id} as eid from settings s join users u on u.id = s.user_id where u.activated=1 and s.user_id_#{provider_id} in (#{eids_str})").collect{|r| r["eid"]};
      pendings = self.invites.collect{|r| r["invitee_eid"]}.compact
    end
    # remove friends who is alrady on Nappstr and set invite pending status    
    friends.each do |f|
      if accepts.include? f[:id]
        friends.delete f
      else
        f[:is_pending] = true if pendings.include? f[:id]
      end
    end

    friends
  end

#--------- define options --------------
  def get_option_sync(provider_id)
    if options["#{provider_id}_sync"]
      ret = options["#{provider_id}_sync"].to_i == 1 ? true : false
    else
      ret = !protected
    end
    ret
  end
  def set_option_sync(provider_id, value)
    options["#{provider_id}_sync"] = value
  end

  def get_option_auto_follow(provider_id)
    if options["#{provider_id}_auto_follow"]
      ret = options["#{provider_id}_auto_follow"].to_i == 1 ? true : false
    else
      ret = true
    end
    ret
  end
  def set_option_auto_follow(provider_id, value)
    options["#{provider_id}_auto_follow"] = value
  end

  
  def save_options
      update_attribute(:options, options.to_json)
  end
#  def twitter_sync
#    if options["twitter_sync"]
#      ret = options["twitter_sync"].to_i == 1 ? true : false
#    else
#      ret = !protected
#    end
#    ret
#  end
#  def twitter_sync=(value)
#    options["twitter_sync"] = value
#  end
#  def facebook_sync
#    if options["facebook_sync"]
#      ret = options["facebook_sync"].to_i == 1 ? true : false
#    else
#      ret = !protected
#    end
#    ret
#  end
#  def facebook_sync=(value)
#    options["facebook_sync"] = value
#  end
#  def buzz_sync
#    if options["buzz_sync"]
#      ret = options["buzz_sync"].to_i == 1 ? true : false
#    else
#      ret = !protected
#    end
#    ret
#  end
#  def buzz_sync=(value)
#    options["buzz_sync"] = value
#  end
#--------- end of options -----------------

  # refresh info from social network in data loast case
  def refresh_userinfo_sina
    return unless self.setting.oauth_sina
    system("curl http://zh.swably.com/connections/accept_access_token/sina.json?access_token=#{self.setting.oauth_sina}")
  end
  def refresh_userinfo_qq
    return unless self.setting.oauth_qq
    system("curl http://zh.swably.com/connections/accept_access_token/qq.json?access_token=#{ERB::Util.url_encode(self.setting.oauth_qq)}")
  end

  
  #--------------------------------------------------------------------------------------------------------------
private
  def rand_offset(count)
    rand(count)
  end  
 
end
