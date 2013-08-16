module ModelHelper

  def display_user
    if user == nil
      ret = User.new
      ret.id = 0
      case self.source
      when "sms"
        ret.name = display_mobile(self.anonymous)
      else
        ret.name = _("Anonymous")
      end
    else
      ret = user
    end
    ret
  end

  def controller_name
    #self[:type].to_s.downcase.pluralize
    "posts"
  end
  
  def view_count_by_access
    ActiveRecord::Base.count_by_sql(["select count(*) from accesses where controller = ? and action = 'show' and item_id = ?", controller_name, id])
  end
  
  def view_count
    ret = read_attribute("view_count")
    unless ret
      ret = view_count_by_access
      update_attribute_without_timestamps(:view_count, ret) 
    end
    ret
  end

  def update_attribute_without_timestamps(name, value)
    self[name] = value;
    update_without_timestamps
  end
  def save_without_timestamps
    update_without_timestamps
  end
  
  def increase_view_count(current_user_id)
    begin
      update_attribute_without_timestamps(:view_count, view_count + 1) unless current_user_id == user_id
    rescue
    end
  end

end