# encoding: utf-8 
# require 'lib/time_util'
require 'yaml'
# require 'soap/wsdlDriver'   
require 'net/pop'
#require 'iconv'    
#require 'console_with_helpers'

class AdminController < ApplicationController
  include CommonHelper

before_filter :log_access #, :only => [] #diable access log for the controller
before_filter :authorize, :except => [:login, :set_enabled, :send_update_all]

def invite
  if request.post?
    params[:number].to_i.times {Invite.new(:invite_code => gen_invite_code).save}
    redirect_to
  end
  @invites_count = Invite.count :all, :conditions => "invitee_id is null and invitor_id is null"
  @invites = Invite.find :all, :conditions => "invitee_id is null and invitor_id is null", :order => "created_at desc", :limit => 100
#  @users_days = User.find_by_sql("select count(*) as c, date(created_at) as d from users group by date(created_at) order by created_at desc limit 30")
end


def send_request
  update_interval = 2 # days
  deadline = Time.now-update_interval*24*3600
  howmany = params[:howmany]
  howmany = howmany.to_i
  subject = params[:subject]
  content = render_to_string :inline => "<%=simple_format(params[:content])%>"
  #from = params[:from].strip
  from = Mailer::FROM
  # 为了从发送失败中跳出，每次从新的记录开始发。
  session[:mailer_offset] = session[:mailer_offset] || -1
  session[:mailer_offset] = session[:mailer_offset] + 1
  user_list = Invite.find :all, :limit => howmany, :offset => session[:mailer_offset], :conditions => ["(invite_at is null or invite_at < ?) and lang=? ", deadline, params[:lang]], :order => 'id'
  session[:mailer_offset] = -1 if user_list.size == 0
  
  send_batch_mail_to(user_list, subject, content, from) do 
    sent = Invite.count( :conditions => "invite_at is not null and lang='#{params[:lang]}'")
    remains = Invite.count( :conditions => "invite_at is null and lang='#{params[:lang]}'")
    [sent, remains]
  end
end



#require "memcache_util"
#def test_memcache
#  Cache.put("test", "test ok")
#  ret = Cache.get("test")
#  render :text => ret
#end


def send_update
  user = User.find(session[:selected_user_id])
  mail = MailmanController.create_update_mail_for_user(user, self)
  if mail
    err = deliver_mail(mail)
    if err
      render :text => error_color("发送给#{user.email}失败!,错误信息:#{escape_string(err)}")
    else
      render :text => "邮件已发送到#{user.email}"
    end
  else
    render :text => "没有更新,未发送邮件"
  end
end

def send_update_all
  update_interval = ENV['mail_update_interval'].to_i # days
  deadline = Time.now-update_interval*24*3600
  @users = User.find(:all, :joins => 'u left outer join onlines o on u.id = o.user_id', :conditions => ["u.enabled = 1 and (o.online_at is null or o.online_at < ?) and (u.subscribe_at is null or u.subscribe_at < ?)", deadline, deadline], :order => "rand()", :limit => params[:count])
  if @users.size > 0 
    failed = false
    str = "#{@users.size} users Begin at #{Time.now.short_time}<br/>"
    @users.each do |user|
      mail = MailmanController.create_update_mail_for_user(user, self)
      if mail
        err = deliver_mail(mail)
        if err
          str += error_color("没能发送给#{user.username}[#{user.email}],错误信息:#{escape_string(err)}<br/>")
          failed = true
        else
          str += "邮件已发送到<a href='/users/show/#{user.id}' target='_blank'>#{user.username}</a>[#{user.email}]<br/>"
        end
      end
      User.find(user.id).update_attribute(:subscribe_at, Time.now) unless failed
    end
    str += "End at #{Time.now.short_time}<hr/>"
  else
    str = "no more at #{Time.now.short_time}<hr/>"
  end
  
  render :text => str
end

def index
end

def mailer
  @site_name = "Bannka用户"
  @is_inner = true;
end

def reset_mailer
  User.connection.execute("update users set invite_at = null") 
  render :text => '复位完成。'
end

def send_inner
  update_interval = 2 # days
  deadline = Time.now-update_interval*24*3600
  howmany = params[:howmany]
  howmany = howmany.to_i
  subject = params[:subject]
  content = render_to_string :inline => "<%=simple_format(params[:content])%>"
  #from = params[:from].strip
  from = Mailer::FROM
  # 为了从发送失败中跳出，每次从新的记录开始发。
  session[:inner_mailer_offset] = session[:inner_mailer_offset] || -1
  session[:inner_mailer_offset] = session[:inner_mailer_offset] + 1
  user_list = User.find :all, :limit => howmany, :offset => session[:inner_mailer_offset], :conditions => ["(invite_at is null or invite_at < ?) ", deadline], :order => 'id'
  session[:inner_mailer_offset] = -1 if user_list.size == 0
  
  send_batch_mail_to(user_list, subject, content, from) do 
    sent = User.count( :conditions => "invite_at is not null")
    remains = User.count( :conditions => "invite_at is null")
    [sent, remains]
  end
end

def gen_user_id
  users = User.find(:all, :conditions => "options is not null", :order => "id")
  users.each do |user|
    options = user.options
    ENV['connections'].split.each do | provider_id |
      value = options["#{provider_id}_user_id"]
      user.setting["user_id_#{provider_id}"] = value
    end
    user.setting.save
  end
  render :text => users.size
end

def lost_apk
  @apps = App.find :all
  ret = []
  @apps.each do |app|
    if app.apk[0,1] == '/'
      path = 'public'+app.apk
#      puts path
#      puts File.exist?(path)
      unless File.exist?(path)
        ret << app.apk
      end
    end
  end
  render :text => "count: " + ret.size.to_s
end

def set_lost_apk_version
  @apps = App.find :all
  ret = []
  @apps.each do |app|
    if app.apk[0,1] == '/'
      path = 'public'+app.apk
#      puts path
#      puts File.exist?(path)
      unless File.exist?(path)
#        ret << app.apk
        app.old_version_code = app.version_code
        app.version_code = -1
        app.save_without_timestamps
#        puts path
      end
    end
  end
  render :text => "done"
end

def import_lvye_org
  @external_users = YAML.load(File.open('lib/lvye_org_users.yml'))
  count = 0
  @external_users.each_value do |user|
    record = ExternalUser.new(user)
    record.account = record.nick # special handle for lvye.info and lvye.org
    begin
      count+=1 if record.save 
    rescue
    end   
  end
  render :text => "绿野org共#{@external_users.size}条记录,成功导入#{count}条记录."
end
def import_lvye_info
  @external_users = YAML.load(File.open('lib/lvye_info_users.yml'))
  count = 0
  @external_users.each_value do |user|
    record = ExternalUser.new(user)
    record.account = record.nick # special handle for lvye.info and lvye.org
    begin
      count+=1 if record.save 
    rescue
    end   
  end
  render :text => "绿野info共#{@external_users.size}条记录,成功导入#{count}条记录."
end

def send_vantica
  update_interval = 2 # days
  deadline = Time.now-update_interval*24*3600
  howmany = params[:howmany]
  howmany = howmany.to_i
  subject = params[:subject]
  content = render_to_string :inline => "<%=simple_format(params[:content])%>"
  #from = params[:from].strip
  from = Mailer::FROM
  # 为了从发送失败中跳出，每次从新的记录开始发。
  session[:mailer_offset_lvye] = session[:mailer_offset_lvye] || -1
  session[:mailer_offset_lvye] = session[:mailer_offset_lvye] + 1
  user_list = ExternalUser.find :all, :limit => howmany, :offset => session[:mailer_offset_lvye], :conditions => ["site_id=1 and (invite_at is null or invite_at < ?) ", deadline], :order => 'id'
  session[:mailer_offset_lvye] = -1 if user_list.size == 0
  
  send_batch_mail_to(user_list, subject, content, from) do 
    sent = ExternalUser.count( :conditions => "site_id=1 and invite_at is not null")
    remains = ExternalUser.count( :conditions => "site_id=1 and invite_at is null")
    [sent, remains]
  end
end


def test

#  respond_to do |format|
#    format.html 
#    format.xml {render :text => "xml"}
#    format.js {render :text => "js"}
#  end
  #MiniblogJiwai.receive

#  groups = Group.find(:all, :conditions => "id = 88727", :order => 'id')
#  robot = "test@goofy2.com"
#  pwd = "test"
#  mail_count = Mailman.new.checkmail_box(robot, pwd, groups[0])
#  render :text => "#{robot} : #{mail_count}", :layout => false
  n = 1234
  step = 26
  ret = dec2any(n, step).join('')
  ret1 = dec2char(n)
  ret2 = char2dec(ret1)
  ret3 = encode_id(n)
  ret4 = decode_id(ret3)
  render :text => "#{ret1},#{ret2}<br/>#{ret3},#{ret4}" , :layout => false
end

#-----------------------------------------------------
private 

def send_batch_mail_to(user_list, subject, content, from)
  err = ""
  howmany = user_list.size
  #err += "发送完毕!<br/>" if howmany <= 0
  #err += "没有输入发件人地址!<br/>" if from == ""
  #if err != ""
  #  render :text => "new Insertion.Top('feedback_panel','#{err}');"
  if howmany <= 0
    render :text => "new Insertion.Top('feedback_panel','继续尝试发送...<br/>');if(stop!=1) setTimeout(function(){$('send').click();},5000);"
  else
    begin_time = Time.now
    sent_count = 0
    to = Array.new
    user_list.each do |user|
      to << user.email
    end
    #err = send_by_multi_yahoo_account(from, to, subject, content+"<hr/>", YAHOO_ACCOUNT_PREFIX, YAHOO_ACCOUNT_COUNT)
    err = send_email(from, nil, subject, content, nil, to) 
    unless err
      #log the send
      sent_count = howmany
      user_list.each do |user|
        user.update_attribute(:invite_at, Time.now)
      end
#      cc_subject = "发送了#{howmany}封，从#{to[0]}到#{to[howmany-1]},主题:#{subject}"
#      cc = "qoofiwatcher@gmail.com"
#      err = send_email(from, cc, cc_subject, content) 
    end
    end_time = Time.now
    sent, remains = yield
    if err
      ret = "new Insertion.Top('feedback_panel','<br/>"+error_color("发送失败!")+"错误信息:#{escape_string(err)}<br/>');"
    else
      ret = "new Insertion.Top('feedback_panel','<br/>本次发送了#{sent_count}封邮件.<br/>');"
    end
    ret += "new Insertion.Top('feedback_panel','<br/>开始于#{begin_time.short_time},结束于#{end_time.short_time}.已发送了#{sent}个用户，还剩#{remains}个用户未发送.');if(stop!=1) $('send').click();"
    render :text => ret
  end
end


## send mail by many account in turn. 
#def send_by_multi_yahoo_account(from, to, subject, content, account_prefix, account_count)
#  session[:yahoo_smtp_account_index] ||= 1
#  old_settings = ActionMailer::Base.server_settings
#  ActionMailer::Base.server_settings = { :address => "smtp.mail.yahoo.com", :port => 25, :domain => "qoofi.com", :authentication => "login", :user_name => "#{account_prefix}#{session[:yahoo_smtp_account_index]}", :password => "1q2w3e4r5t" }
#  err = send_email(from, to, subject, content)
#  ActionMailer::Base.server_settings = old_settings
#  session[:yahoo_smtp_account_index] += 1 if err
#  session[:yahoo_smtp_account_index] = 1 if session[:yahoo_smtp_account_index] > account_count
#  err
#end

end

