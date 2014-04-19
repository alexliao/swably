require 'net/http'
require 'rexml/document'
require 'cloudfiles'
require 'RMagick.rb'

class App < ActiveRecord::Base
  include CommonHelper
  include ModelHelper
  include FileHelper
  has_many :locales, :class_name => "AppLocale"
  has_and_belongs_to_many :uploaders, :class_name => "User", :foreign_key => "app_id", :association_foreign_key => "user_id", :join_table => "shares"
  has_many :comments
  has_many :likes
  has_and_belongs_to_many :liked_by_users, :class_name => "User", :foreign_key => "app_id", :association_foreign_key => "user_id", :join_table => "likes"
  belongs_to :dev, :class_name => 'User', :foreign_key => 'dev_id'
  has_and_belongs_to_many :uploaders, :class_name => "User", :join_table => "shares"

  # constant for move apk to cloud storage
  # CACHE_SIZE = 4000 
  CACHE_SIZE = 0
  BATCH_SIZE = 1000
  CLOUD_FILE_CONTAINER = "swably-data"
  CLOUD_FILE_USERNAME = "alex445"
  CLOUD_FILE_API_KEY = "2a802403c95580a7c8190f42a7f4dbdf" 

  def facade(current_user = nil, options = {})
    ret = {}
    ret[:id] = self.id
    ret[:name] = options[:lang] ? self.local_name(options[:lang]) : self.name
    ret[:package] = self.package
    ret[:version_name] = self.version_name
    ret[:version_code] = self.version_code
    ret[:size] = self.size
    ret[:icon] = self.display_icon.thumbnail
    ret[:banner] = self.display_banner.medium
    # if current_user and current_user.client_version and current_user.client_version.to_i > 1820
    #   ret[:apk] = "/apps/download/#{self.id}?r=app"
    # else
    #   ret[:apk] = self.apk + "?r=app" if self.apk
    # end
    ret[:apk] = self.apk + "?r=app" if self.apk
    ret[:enabled] = self.enabled
    ret[:updated_at] = self.updated_at.to_i
    ret[:signature] = self.signature
    ret[:row] = self[:row]
    unless options[:names_only]
      ret[:created_at] = self.created_at.to_i
      if self.id
        #ret[:is_shared_by_me] = current_user.is_sharing(self.id) ? true : false if current_user
        #ret[:users_count] = self.users.count
        ret[:description] = self.description
        ret[:contact] = self.contact || self.dev_extemail
#        ret[:review] = self.last_review
        ret[:reviews_count] = self.reviews_count
        ret[:likes_count] = self.likes_count
        ret[:is_liked] = current_user.is_liking(self.id) ? true : false if current_user
        ret[:like_id] = self[:like_id] if self[:like_id]
        ret[:dev] = self.dev.facade(nil, options.merge(:names_only => true)) if self[:dev_id] && self.dev
        @recent_uploaders = self.uploaders.find :all, :order => "share_id desc", :limit => 3
        ret[:recent_uploaders] = @recent_uploaders.facade(current_user, :lang => options[:lang], :names_only => true)
        ret[:uploaders_count] = self.uploaders.count
        ret[:upload_id] = self[:share_id] if self[:share_id]
        ret[:uploaded_at] = self[:uploaded_at].to_i if self[:uploaded_at]
     end
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

  def last_review(refresh = false)
    ret = refresh ? nil : read_attribute("review")
    unless ret
      ret = self.comments.find :first, :conditions => 'in_reply_to_id is null and content <> ""', :order => 'id desc'
      app = App.find_by_id self.id # self may be readonly record
      app.update_attribute(:review, ret ? ret.facade.to_json : "")
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

#  def local_name(code)
#    locale = locales.find(:first, :conditions => ["code = ?", code])
#    ret = locale.name if locale
#    unless ret
#      a = code.split("_")
#      locale = locales.find(:first, :conditions => ["code = ?", a[0]])
#      ret = locale.name if locale
#    end
#    ret || self.name
#  end

  def local_name(languages)
    ret = nil
    if languages
      lrs = languages.split(",")
      lrs.each do |lr|
        code = lr.split(";")[0]
        locale = locales.find(:first, :conditions => ["code = ?", code])
        ret = locale.name if locale
        break if ret
      end
    end
    ret || self.name
  end

  def display_icon
    path = icon || ""
    if path == ""
      path = '/images/noimage.png'
    end
    Photo.new(path)
  end

  def display_banner
    path = '/images/banner1.png'
    Photo.new(path)
  end

  # Composite icon on swably feature art to ensure the size of sharing image is large enough for Facebook and Google+ using.
  def icon4share
    icon_path = self.display_icon.original
    icon4share_path = icon_path + "4share.jpg"
    unless File.exist?('public'+icon4share_path)
      back = Magick::Image.read('public/images/back4share.jpg').first
      icon = Magick::Image.read('public'+icon_path).first
      result = back.composite(icon, Magick::CenterGravity, Magick::OverCompositeOp)
      result.write('public'+icon4share_path)
    end
    icon4share_path
  end

  def self.copy2cloud(options = {})
    batch_size = options[:batch_size] || BATCH_SIZE
    cache_size = options[:cache_size] || CACHE_SIZE
    container = options[:container] || CLOUD_FILE_CONTAINER
    apps = App.find :all, :conditions => "left(apk,1) = '/' and version_code > -1", :order => "updated_at desc", :limit => batch_size, :offset => cache_size # version_code == -1 means missed apk file in local harddisk
    puts "will copy " + apps.size.to_s
    cf = CloudFiles::Connection.new(:username => CLOUD_FILE_USERNAME, :api_key => CLOUD_FILE_API_KEY)
    container = cf.container(container)
    apps.each do |app|
      copy_apk(app, container)
    end
  end

  def self.copy_apk(app, container)
    begin
      path = app.apk
      return unless path
  #    cloud_name = local_path2cloud_name(path)
  #    cloud_name = app.apk[1..-1]  # remove leading /
      cloud_name = "#{app.package}_#{app.signature}.apk"
  #puts cloud_name
      object = container.create_object(cloud_name, false)
      if object.write(File.open("public"+path, "rb"))
#        app.on_cloud = true
#        app.apk = object.public_url
#        app.save
        app.update_attribute_without_timestamps :apk, object.public_url         
        puts "Copied to "+object.public_url
      end
    rescue Exception => e
      puts e
    end
  end
  
  def self.remove_useless_local_apk
    local_apk_dir = "public/apks"
    Dir.glob(local_apk_dir+"/*") do |sub|
      if File.directory?(sub)
#puts "sub "+sub
#puts "size "+Dir.glob(sub+"/*.apk").size.to_s
        if Dir.glob(sub+"/*.apk").size == 0
          FileUtils.rm_rf(sub) 
          puts "Deleted #{sub}"
        end
        Dir.glob(sub+"/*.apk") do |file|
          url = file[6..-1] # remove prefix 'public'
#puts "url "+url 
          app = App.find :first, :conditions => "apk = '#{url}'"
#puts app
          unless app
            FileUtils.rm(file)
            puts "Deleted #{file}"
          end
        end
      end
    end
  end
  
#  def self.local_path2cloud_name(path)
#    path.gsub "/", "_"
#  end

  # recover review from app cache in data lost case.
  def save_review
    return unless self.review
    begin
      r = JSON.parse self.review
      c = Comment.new
      c.id = r['id']
      c.content = r['content']
      c.user_id = r['user']['id']
      c.app_id = r['app']['id']
      c.created_at = Time.at r['created_at']
      c.model = r['model']
      c.sdk = r['sdk']
      c.image = r['image']
      c.image_size = r['image_size']
      c.sns_status_id = r['sns_status_id']
      c.sns_id = r['sns_id'] 
      c.in_reply_to_id = r['in_reply_to_id']
      c.save
    rescue
    end
  end
end
