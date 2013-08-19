# require 'exifr'
class Mailer < ActionMailer::Base
  include CommonHelper
  include ModelHelper
  include FileHelper
  # include GetText
  # bindtextdomain "main"
  helper ApplicationHelper # for referring __() in rhtml
  helper ActionView::Helpers::UrlHelper
  
  #FROM = IconvUtil.new.utf8_to_gbk('"高飞"<no-reply@gaofei2.com>')
  FROM = '"Swably"<no-reply@swably.com>'
  
  def simple_mail(from, to, subject, body, cc = nil, bcc = nil)
    @sent_on    = Time.now
    @from = from
    @recipients = to
    @cc = cc
    @bcc = bcc
    @subject    = subject
    @headers    = {}
    @content_type = "text/html"
    @body = {:content => body}
  end
  
  def reset_password(email, users)
    @sent_on    = Time.now
    @from = FROM
    @recipients = email
    @subject    = _('Reset password')
    @headers    = {}
    @content_type = "text/html"
    @body = {:users => users}  
  end
  
#  def my_update(controller, to_user, items)
#    @sent_on    = Time.now
#    @from = FROM
#    @recipients = to_user.email
#    _count = items[:new_direct_message_count]+items[:new_unread_count]
#    @subject    = __(_('您在高飞上有#{_count}条新消息'),binding)
#    @headers    = {}
#    @content_type = "text/html"
#    @body = {:controller => controller, :user => to_user }.merge(items)  
#  end

  def follow(user, receiver)
    @sent_on    = Time.now
    @from = FROM
    @recipients = receiver.email
    temp_user_locale(receiver) do
      @subject    = _('%s is now following you on Swably!')%user.display_name
    end
    @headers    = {}
    @content_type = "text/html"
    @body = {:user => user, :receiver => receiver}  
  end

  def approval(user, receiver)
    @sent_on    = Time.now
    @from = FROM
    @recipients = receiver.email
    temp_user_locale(receiver) do
      @subject    = _('You are following %s on Swably!')%user.display_name
    end
    @headers    = {}
    @content_type = "text/html"
    @body = {:user => user, :receiver => receiver}  
  end

  def request(user, receiver)
    @sent_on    = Time.now
    @from = FROM
    @recipients = receiver.email
    temp_user_locale(receiver) do
      @subject    = _('%s requests to follow you on Swably!')%user.display_name
    end
    @headers    = {}
    @content_type = "text/html"
    @body = {:user => user, :receiver => receiver}  
  end

  def update(update, receiver)
    @sent_on    = Time.now
    @from = FROM
    @recipients = receiver.email
    temp_user_locale(receiver) do
      @subject    = _('Update from %s on Swably')%update.user.username
    end
    @headers    = {}
    @content_type = "text/html"
    @body = {:update => update, :receiver => receiver}  
  end

  def comment(comment, receiver)
    @sent_on    = Time.now
    @from = FROM
    @recipients = receiver.email
    temp_user_locale(receiver) do
      @subject    = _("Comment on %s's update #%d")%[comment.upload.user.username, comment.upload_id]
    end
    @headers    = {}
    @content_type = "text/html"
    @body = {:comment => comment, :receiver => receiver}  
  end

#  def reply(controller, receiver, ideas)
#    @sent_on    = Time.now
#    @from = FROM
#    @recipients = receiver.email
#    temp_user_locale(receiver) do
#      @subject    = _('今天在高飞上有人对你说')
#    end
#    @headers    = {}
#    @content_type = "text/html"
#    @body = {:controller => controller, :receiver => receiver, :ideas => ideas}
#  end

  def task(type, id)
    @sent_on    = Time.now
    @from = FROM
    @recipients = ENV['queue']
    @subject    = type
    @headers    = {}
    @content_type = "text/html"
    @body = {:content => id}  
  end


  def receive(email)
#  puts "from: "+email.from[0]
#  puts "to: "+email.to[0]
#  puts "subject: "+email.subject
#  puts "body:"+email.body
    logger.info("#{Time.now.short_time} received mail from: #{email.from}, to: #{email.to}, subject: #{email.subject}")
    addr = email.to[0].to_s
    addr.gsub!('"','')
    if addr == ENV['queue']
      run_task(email)
    else
      user = get_user(addr)
      count = 0
      if user
        if email.has_attachments?
          title = get_title(email)
  #puts title        
          email.attachments.each do |attachment|
            if attachment.content_type =~ /image/
              count += 1 if add_upload(attachment, title, user, email)
            end
          end
        end
        err = _('Nothing to upload. Please attach some photos.') if count == 0
      else
        err = _('Invalid Email address [%s] for uploading to Swably.')%to
      end
  
  #puts err if err
      logger.info("#{Time.now.short_time} Uploaded #{count} photos via Email ") if count > 0
      logger.info("#{Time.now.short_time} Abandon Email for: " + err) if err
    end
       
  end
  
private 

#   def run_task(email)
#     type = email.subject
#     id = email.body.strip
#     case type
#     when "new_update"
#       iu = Upload.find(:first, :conditions => "id=#{id}")
#       if iu
#         puts iu.id
#         iu.notify_followers
#         iu.user.sync(iu)
#       end      
#     when "new_comment"
#       cm = Comment.find(:first, :conditions => "id=#{id}")
#       if cm
#         puts cm.id
#         cm.notify_followers
#       end      
#     when "connect"
#       params = id.split
#       user_id = params[0]
#       provider_id = params[1]
#       u = User.find(:first, :conditions => "id=#{user_id}")
#       if u
#         puts u.id
#         puts provider_id
#         u.sync_graph(provider_id)
#       end      
#     end
#   end

#   def get_title(email)
#     ret = nil
#     ret = email.subject unless email.in_reply_to
#     ret = get_text(email, 'plain').split("\n")[0] if ret.blank?
#     ret = truncate_ex(ret ,100) if ret
#     ret
#   end
#   #get text part from mail iterally
#   def get_text(mail, sub_type)
#     ret = nil
#     if mail.parts.size == 0 
#       ret = mail.body if mail.main_type == 'text' and mail.sub_type == sub_type
#     else
#       mail.parts.each do |part|
#         ret = get_text(part, sub_type)
#         break if ret
#       end
#     end
#     ret
#   end

#   def add_upload(attachment, title, user, email)
# #    begin
#       #infos = {:width => params[:width], :height => params[:height], :shot_at => params[:shot_at], :time_zone => params[:time_zone], :upload_at => params[:upload_at], :longitude => params[:longitude], :latitude => params[:latitude], :altitude => params[:altitude], :bias => params[:bias], :caption => params[:caption], :model => params[:model], :fingerprint => params[:fingerprint], :sdk => params[:sdk], :client_os => params[:client_os], :client_version => params[:client_version]}
#       infos = {:upload_at => email.date(Time.now), :caption => title, :fingerprint => email.from, :client_os => "Email", :client_version => "1"}
#       save_url = save_image(attachment, infos)
#       if save_url
#         iu = Upload.create(infos.update({:url=>save_url, :user_id=>user.id}), true)
#       end
#       return iu
# #    rescue Exception => e
# #      logger.error("#{Time.now.short_time} Custom log : Exception in Mailer.add_upload " + e)
# #    end
#   end

#   def save_image(attachment, infos)
#     #save to file
#     save_name = ((Time.now-Time.gm(2007))*1000).to_i.to_s
#     postfix = sub_type(attachment)
#     save_name = "#{save_name}.#{postfix}"
#     save_url = "#{get_picture_dir}/#{save_name}"
#     save_path = "public#{save_url}"
#     File.open(save_path, "wb") { |f| f.write(attachment.read) }
#     size = File.size(save_path)
#     if size > 2100000
# puts "Too big, delete #{save_path}"
#       File.delete(save_path)
#       logger.info("#{Time.now.short_time} Attachment size #{size} too big, deleted.")
#       save_url = nil
#       puts
#     else
#       get_metadata(save_path, infos) if postfix == 'jpg'
#       #crop to 500*500
#       infos[:width], infos[:height], infos[:size] = Photo.create_thumbnail(save_url, save_path, 500)
#       #system "chmod", "666", save_path # no need because add "umask 000" into procmailrc
#     end    
#     return save_url
#   end
  
#   def get_metadata(path, infos)
#     obj = EXIFR::JPEG.new(path)
#     if obj.exif?
#       exif = obj.exif[0]
#       #print_exif(exif)
#       #get shot_at
#       shot_at = exif.date_time_original || exif.date_time || exif.date_time_digitized
# #puts shot_at      
#       #infos[:shot_at] = shot_at.strftime('%Y-%m-%d %H:%M:%S') if shot_at
#       infos[:shot_at] = shot_at
#       #get GPS info
#       if exif.gps_latitude
#         lat = exif.gps_latitude[0].to_f + (exif.gps_latitude[1].to_f / 60) + (exif.gps_latitude[2].to_f / 3600)
#         lat = lat * -1 if exif.gps_latitude_ref == 'S'    # (N is +, S is -)
#         infos[:latitude] = lat
#       end
#       if exif.gps_longitude
#         long = exif.gps_longitude[0].to_f + (exif.gps_longitude[1].to_f / 60) + (exif.gps_longitude[2].to_f / 3600)
#         long = long * -1 if exif.gps_longitude_ref == 'W' # (W is -, E is +)
#         infos[:longitude] = long
#       end
#       if exif.gps_altitude
#         alt = exif.gps_altitude.to_i
#         alt = alt * -1 unless exif.gps_altitude_ref.nil? or exif.gps_altitude_ref.strip.empty?
#         infos[:altitude] = alt
#       end
#       infos[:model] = exif.model
#       infos[:sdk] = exif.software
#     end
#   end
#   def print_exif(exif)
#     puts "--- EXIF information ---".center(50)
#     hash = exif.to_hash
#     hash.each_pair do |k, v|
#       puts "-- #{k.to_s.rjust(20)} -> #{v}"
#     end
#   end
    
#   # addr should like : "alex-abcd@bannka.com"
#   def get_user(addr)
#     user = nil
#     begin
#       lh = addr.split('@')[0].split("-")
#       if lh.size == 2
#         username = lh[0]
#         user_id = decode_id(lh[1])
#         if user_id
#           user = User.find(:first, :conditions => ["username=? and id=?", username, user_id])
#         end                
#       end
#     rescue Exception => e
#       logger.error("#{Time.now.short_time} Custom log : Exception in Mailer.get_user: " + e)
#     end
#     user
#   end

  def engage_dev(email, reviews, app)
    @sent_on    = Time.now
    @from = FROM
    @recipients = email
    @subject    = _('What are people talking about your app %s ?' )%(app.local_name('en'))
    @headers    = {}
    @content_type = "text/html"
    @body = {:email => email, :reviews => reviews, :app => app}  
  end

  def self.engage_dev(limit=10000000000, test_email = nil)
    puts "engage_dev start"
    logger.info("#{Time.now.short_time} Custom log : engage_dev start")
    
    # get apps for this time of running which commented after last time of engagement
    begin_time = Time.now
    app_ids = ActiveRecord::Base.connection.execute("select app_id, count(app_id) as count from comments c join apps a on c.app_id = a.id where (a.dev_engaged_at is null or a.dev_engaged_at < c.created_at) and length(c.content) > 8 group by c.app_id limit #{limit}")
    end_time = Time.now
    puts "duration: #{end_time - begin_time}"
    sent_count = 0
    app_ids.each do |id|
      app = App.find_by_id(id)
      puts "_"*60
      puts "Package: #{app.package}"
      email = get_dev_email(app)
      puts "Email: #{email}"
      if email
#        puts ExcludeEmail.find_by_email(email)
        engage_a_dev(app, test_email || email, app.dev_engaged_at) unless ExcludeEmail.find_by_email(email)
        sent_count += 1
      end
    end
    puts "engage_dev finished with sending email for #{sent_count}/#{app_ids.num_rows} apps"
    logger.info("#{Time.now.short_time} Custom log : engage_dev finished with sending email for #{sent_count}/#{app_ids.num_rows} apps")
  end

  ENGAGE_REVIEW_LIMIT = 20  
  # send recently reviews of the app to dev email
  def self.engage_a_dev(app, email, last_engaged_at)
#    puts app_id
    reviews = Comment.find :all, :include => :user, :conditions => ["app_id = #{app.id} and comments.created_at > ?", last_engaged_at || Time.utc(0)], :order => "comments.id desc", :limit => ENGAGE_REVIEW_LIMIT
    reviews.reverse!
    puts "reviews:#{reviews.size}"
    mail = Mailer.create_engage_dev(email, reviews, app)
#    puts mail
    Mailer.deliver(mail)
    app.update_attribute_without_timestamps(:dev_engaged_at, Time.now)
    logger.info("#{Time.now.short_time} Custom log : engage_dev delevered engage email to #{email} for app #{app.name} id #{app.id}")
  end
  
  CRAWL_EXPIRES = 7*3600
  # return email or nil
  def self.get_dev_email(app)
    if (Time.now - (app.dev_extemail_updated_at || Time.utc(0)) > CRAWL_EXPIRES) # need to be update
      email = crawl_email(app.package)
      if email
        app.dev_extemail_updated_at = Time.now
        app.dev_extemail = email.empty? ? nil : email
        app.update_without_timestamps
      end
    end
    
    return app.dev_extemail
  end
  
  # crawl dev email from google play store for the specific app
  # return email; nil - temporarily failed; "" - no dev email available; 
  def self.crawl_email(package)
    ret = nil
    url = "https://play.google.com/store/apps/details?id=#{package}&hl=en" # must get English version, or the match will be failed
    uri = URI.parse(url)
    ses = Net::HTTP.new(uri.host, uri.port)
    ses.use_ssl = true
    ses.verify_mode = OpenSSL::SSL::VERIFY_NONE
    puts "crawling #{url}"
    begin
      resp = ses.get(url)
      if resp.class == Net::HTTPOK
        html = resp.body
        # sample:  <a href="mailto:alex197445@gmail.com" rel="nofollow">Email Developer</a>
        # html = '<a href="mailto:alex197445@gmail.com" rel="nofollow">Email Developer</a>'
        regex = /href="mailto:([^"]+)"[^>]*?>Email Developer</
        ret = html =~ regex ? $1 : ""
  #      puts package if ret == ""
      else
        ret = ""
  #      puts url + ": " + resp.code + " - " + resp.body
      end
    rescue
    end    
    return ret
  end
  
end


