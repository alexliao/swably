require "base64"
module CommonHelper
  def truncate_ex(text, length = 30)
    if text.nil? then return end
    truncate_string = "..."
    length = length * 2
    l = length - 4
    if $KCODE == "NONE"
      text.length > length ? text[0...l] + truncate_string : text
    else
      chars = text.split(//)
      ret = ""
      chars.each do |s|
        ret += s
        l -= s.size > 1 ? 2 : 1 
        break if l <= 0
      end
      ret += truncate_string if ret.size < text.size
      ret
    end
  end
  
  def __(str, b)
    eval %("#{str}"), b
  end

  def temp_user_locale(user)
    user = User.find(user) unless user.class == User
    old = GetText.locale
    set_locale user.lang
    yield
    set_locale old
  end
  
  def temp_locale(lang)
    old = GetText.locale
    set_locale lang
    yield
    set_locale old
  end

  #deliver mail, return nil if success, or error message
  def deliver_mail(mail)
    begin
      mail.subject = "=?#{mail.charset}?b?#{Base64.encode64(mail.subject)}?="
      Mailer.deliver(mail)
      return nil
    rescue Exception => exc
      return exc.message
    end
  end
  
  def validate_email(str)
    r = /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
    str.match(r)
  end
  
  def encode_invite_id(user_id)
    "#{user_id}-#{User.hash_password(user_id.to_s)[0,6]}"
  end
  def decode_invite_id(id)
    ret = nil
    a=id.split("-")
    if a.size == 2
      user_id = a[0]
      key = a[1]
      ret = user_id.to_i if User.hash_password(user_id)[0,6] == key
    end
    ret
  end

  # repeat last bit, and convert to string. e.g. 1234 -> 12344 -> sgu
  # calculate and save 校验和
  MAX_CHECK_SUM = 32 # must be binary step
  def encode_id(id)
    sum = 0
    a = dec2any(id, MAX_CHECK_SUM)
    a.each {|d| sum ^= d}
    a << sum
    dec2char(any2dec(a, MAX_CHECK_SUM))
  end
  
  def decode_id(str)
    num = char2dec(str)
    # validate the num
    sum = 0
    a = dec2any(num, MAX_CHECK_SUM)
    a.each {|d| sum ^= d}
    if sum == 0
      a.pop
      ret = any2dec(a, MAX_CHECK_SUM)
    else
      ret = nil
    end
    ret
  end
  
  def char2dec(str)
    str = str.downcase
    arr = []
    1.upto(str.size) {|i| arr << str[i-1]-97}
    any2dec(arr, 26)
  end
  
  def any2dec(num_arr, step)
    ret = 0
    n = num_arr.size
    1.upto(n) {|i|  ret += num_arr[i-1]*step.rpower(n-i) }
    ret
  end
  
  def dec2char(num)
    arr = dec2any(num, 26)
    str = ""
    arr.each {|bit| str += (bit+97).chr}
    str
  end
  
  def dec2any(num, step)
    ret = []
    _dec2any(num, step, ret)
    ret.reverse
  end
  
  def _dec2any(num, step, ret)
    rest = num / step
    ret << num % step
    if rest > 0
      _dec2any(rest, step, ret)
    end
  end

  def expire_notify(user_id)
    begin
      ActionController::Base.expire_page("/feeds/check/#{user_id}")
    rescue
      puts e
    end
  end  

end

class Object
  # stub for migration from gettext to rails 3
  def self._(str)
    str
  end

end