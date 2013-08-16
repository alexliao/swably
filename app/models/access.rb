# require 'lib/time_util'
class Access < ActiveRecord::Base
  
#  def self.save2disk
#    batch_count = 1000
#    condition = "created_at < subdate(date(now()), interval 30 day)"
#    count = Access.count(condition)
#    save_times = (count / batch_count).to_i + 1
#    puts "Start saving #{count} recent accesses to disk at #{Time.now.short_time}"
#    save_times.times do 
#      ActiveRecord::Base.connection.execute("insert into accesses (controller, action, item_id, method, is_xhr, remote_ip, http_user_agent, http_referer, query_string, user_id, created_at, tag_id, duration) select controller, action, item_id, method, is_xhr, remote_ip, http_user_agent, http_referer, query_string, user_id, created_at, tag_id, duration from accesses where #{condition} order by created_at limit #{batch_count} ")        
#      print "#{batch_count} saved "
#      ActiveRecord::Base.connection.execute("delete from accesses where #{condition} order by created_at limit #{batch_count} ")        
#      puts "#{batch_count} deleted"
#      sleep(1)
#    end
#    puts "End saving recent accesses to disk at #{Time.now.short_time}"
#  end

#  def self.clean_history
#    keep_days = 90
#    ActiveRecord::Base.connection.execute("delete from accesses where created_at < subdate(date(now()), interval #{keep_days} day)")        
#  end

  def self.clean_history
    keep_days = 30
    ActiveRecord::Base.connection.execute("delete from accesses where created_at < subdate(date(now()), interval #{keep_days} day)")        
  end

  
end
