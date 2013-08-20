# Methods added to this helper will be available to all templates in the application.
# require 'lib/time_util' 
module ApplicationHelper

  def space(num = 1)
    " " * num
  end
  
  # def get_BOM
  #   bom = '廖'
  #   bom[0] = 0xEF
  #   bom[1] = 0xBB
  #   bom[2] = 0xBF
  #   bom
  # end
  
  # # fix IE bug: 任一个字符加上BOM(FFFE)会成为单独的一行
  # def render_ex(options = nil, deprecated_status = nil, &block)
  #   ret = render(options, deprecated_status, &block)
  #   ret.gsub(get_BOM, '')
  # end

  #treat a Chinese character as 2 English characters to keep the result looks the same length. works for utf-8 string.
  def truncate_ex(text, length = 30, truncate_string = "...", force = false)
    if text.nil? then return end
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
      ret += truncate_string if force or ret.size < text.size
      ret
    end
  end

  # insert html tag attributes to <select>. 
  def add_attributes_for_select(select_html, attributes)
    select_html.gsub("<select ", "<select " + attributes + " ")
  end
  
  def img_fit(src, size, html_options={})
    html_options[:onload] = "fit_size(this, #{size})"
    image_tag(src, html_options)
  end

  def img_square(src, size, html_options={})
    html_options[:onload] = "square_size(this, #{size})"
    image_tag(src, html_options)
  end

  def div_square(size, html)
    "<div style=\"width:#{size}px;height:#{size}px;overflow:hidden;\">#{html}</div>"
  end
  
  #create a link to user page
  def link_to_user_name(user, html_options = {}, length = 10)
    name = truncate_ex(h(user.username), length)
    unless html_options[:size] == nil
      name = truncate_ex(user.username, html_options[:size])
      html_options[:title] = user.username
    end
    name = h(name)
    if user.id == 0
      name
    else
      link_to(name, "/#{user.id}", html_options)
    end
  end
  
  def user_icon(user,size,no_online=true, show_level2=false)
    tip_id = "tip#{rand(100000)}"
    if user.id > 0 
      img_user = "<img src='#{user.display_photo.by_size(size)}' class='pointer' width='#{size}' alt='#{user.username}' title='#{user.username}' #{level2_onmouse(tip_id, user.id) if show_level2}> "
      ret = "<div style='width: #{size}px; height: #{size}px;'>" + img_user 
      ret += lazy_level2(tip_id) if show_level2
      ret += online_icon if no_online == false and size > 16 and user.is_online
      ret += "</div>"
      ret += "<script>timeout0_#{tip_id}=null;timeout1_#{tip_id}=null;timeout2_#{tip_id}=null;</script>" if show_level2
    else
      ret = "<div style='width: #{size}px; height: #{size}px;'><img src='#{user.display_photo.by_size(size)}'  width='#{size}'  /></div>"
    end
    ret 
  end
  
  def online_icon
    
    "<img src='/images/online.gif' style='position: relative; width: 16px; left:0px; top:-16px;'/>"
  end
  
  def link_to_user_icon(user,size,link_params = nil, html_options = {})
    if user.id > 0 
      tip_id = "tip#{rand(100000)}"
      img_user = "<img src='#{user.display_photo.by_size(size)}' class='pointer' width='#{size}' alt='#{user.username}' title='#{user.username}'> "
      link = link_params ? link_to(img_user, link_params, html_options) : link_to_meta_data(img_user,user, html_options)
      ret = "<div style='width: #{size}px; height: #{size}px;'>" + link
      ret += "</div>"
    else
      ret = "<div style='width: #{size}px; height: #{size}px;'><img src='#{user.display_photo.by_size(size)}'  width='#{size}'  /></div>"
    end
    ret 
  end
  
  def link_to_remote_user_icon(user,size,options = {},html_options = {})
    image = image_tag(user.display_photo.by_size(size), :class => "member_image", :width => size, :height => size)
    ret = link_to_remote image, options, html_options
  end  
  
  def location_of_current_user
    IpAddress.location_of(request.remote_ip)
  end
  
  
  def icon_with_text(icon_path, text, size = nil)
    if size
      "<span style='padding: #{size-16}px; padding-left: #{size+4}px; background:url(#{icon_path}) no-repeat left center;' />#{text}</span>"
    else
      "<span style='padding-left: 20px; background:url(#{icon_path}) no-repeat left center;' />#{text}</span>"
    end
    #"<div><img src=\"#{icon_path}\" style='float:left;' border=0 />&nbsp;#{text}</div>"
  
  end
  
  def link_to_candlelit(name, url, width, title = nil, html_options = {}, options = {})
    title = name unless title
    html_options[:class] = html_options[:class] || ''
    html_options[:class] += ' local'
    options[:update] = "dialog.panel"
    options[:method] = :get
    options[:url] = url
    options[:loading] = "show_dialog('#{width}', '#{title}')"
    #link_to_function name, "if($('dialog.panel').innerHTML != ''){Element.show('dialog.candlelit');}else{#{remote_function(options)}}", html_options
    link_to_remote name, options, html_options
  end
  
  def h_ex(str)
    and_str = "_1234567890987654321_"
    str.gsub!('&',and_str)
    str = h(str)
    str.gsub!(and_str, "&")
    str
  end
  
  def simple_format_ex(value)
    #return value
    value = value || ''
    #ret = simple_format(preview_urls(sanitize(value), :target => '_blank'))
    #ret = ret[3..-5] #remove "<p></p>" which added by simple_format
    ret = preview_urls(sanitize(value), :target => '_blank')
    ret.gsub!(/(\r\n|\n|\r)/, "\n") # lets make them newlines crossplatform
    ret.gsub!(/\n\n+/, "\n\n") # zap dupes
    ret.gsub!("\n", '<br />') # turn newline into <br />
    ret
  end

  # h and auto_link
  def h_link(text, preview = false, thumbnail = false)
    h_ex(text).gsub(G2_AUTO_LINK_RE) do
      all, a, b, c, d = $&, $1, $2, $3, $5
      b = "http://www." if b=="www."
      text = b + c
      temp = preview ? url_type(text) : 'html'
      preview = render(:partial => "previews/#{temp}", :locals => {:thumbnail => thumbnail, :url => text, :tailer => d, :header => a})
      %(#{a}#{preview})
    end
  end

#  # h and auto_link
#  def h_link(text)
#    ret = simple_format(text)
#    ret = ret[3..-5] #remove "<p></p>" which added by simple_format
#    h(ret)
#  end
  
  def render_in_candlelit(candlelit_id, title, width, options)
    render :partial =>'shared/candlelit', :locals => {:candlelit_id => candlelit_id, :title => title, :width => width, :options => options}
  end
#  

  def link_to_meta_data(name, object, html_options = {})
    #target = "#{object.controller_name}#{object.id}" 
    #html_options[:target] = html_options[:target] || target if ENV['host'] == 'goofy2.com'
    link_to(name, "/#{object.controller_name}/show/#{object.id}", html_options)
  end
  def link_to_meta_data_unless_current(name, object, html_options = {})
    #target = "#{object.controller_name}#{object.id}" 
    #html_options[:target] = html_options[:target] || target
    link_to_unless_current(name, "/#{object.controller_name}/show/#{object.id}", html_options)
  end

  def text_field_self_help(object_name, method, help, options = {})
    field_self_help(object_name, method, help, options) {text_field(object_name, method, options)}
  end
  def password_field_self_help(object_name, method, help, options = {})
    field_self_help(object_name, method, help, options) {password_field(object_name, method, options)}
  end
  def text_area_self_help(object_name, method, help, options = {})
    field_self_help(object_name, method, help, options) {text_area(object_name, method, options)}
  end
  def field_self_help(object_name, method, help, options = {})
    field_id = options[:id] || "#{object_name}_#{method}"
    help_id = "self_help_#{field_id}"
    ret = "<div class='self_help' id='#{help_id}_box'><div id='#{help_id}' class='text'  onclick='Element.hide(this); $(\"#{field_id}\").focus();'>#{help}</div>"
    if options[:no_timer].nil?
      timer_var = "#{help_id.gsub('.', '_')}_timer"
      options[:onfocus] = (options[:onfocus] || '') + "; #{timer_var} = setInterval(function(){toggle_self_help('#{help_id}', ($('#{field_id}').value == ''));}, 500);"
      options[:onblur] = (options[:onblur] || '') + "; clearInterval(#{timer_var});"
    else
      options[:onfocus] = (options[:onfocus] || '') + "; toggle_self_help('#{help_id}', false);"
      options[:onblur] = (options[:onblur] || '') + "; toggle_self_help('#{help_id}', ($('#{field_id}').value == ''));"
    end
    options[:onchange] = (options[:onchange] || '') + "; toggle_self_help('#{help_id}', ($('#{field_id}').value == ''));"
    ret += yield
    #ret += "<script>#{timer_var} = setInterval(function(){toggle_self_help('#{help_id}', ($F('#{field_id}') == ''));}, 500);</script></div>"
    ret += "<script>toggle_self_help('#{help_id}', ($('#{field_id}').value == ''));</script>"
    ret += "</div>"
  end
  
  def avatar48(user, no_online = true)
    "<div class='avatar48'>"+user_icon(user, 48, no_online)+"</div>"
  end

  def count_unless_0(count)
    count == 0 ? '' : "(#{count})"
  end

  def paginator(pages, options={}, html_options={})
    options[:window_size] = options[:window_size] || 3
    options[:params] = options[:params] || params || {}
    prev_url = options[:params].clone
    prev_url[:page] = pages.current.previous
    next_url = options[:params].clone
    next_url[:page] = pages.current.next
    ret = ""
    ret += link_to('&nbsp;<&nbsp;', prev_url) + "&nbsp;&nbsp;"  if pages.current.previous
    ret += "#{pagination_links(pages, options, html_options)}"
    ret += "&nbsp;&nbsp;" + link_to('&nbsp;>&nbsp;', next_url) if pages.current.next
    ret
  end
  
  # def prev_next(pages, options={}, html_options={})
  #   options[:window_size] = 0
  #   options[:params] = options[:params] || params || {}
  #   prev_url = options[:params].clone
  #   prev_url[:page] = pages.current.previous
  #   next_url = options[:params].clone
  #   next_url[:page] = pages.current.next
  #   ret = ""
  #   ret += link_to('上一页', prev_url) + "&nbsp;&nbsp;"  if pages.current.previous
  #   ret += "#{pagination_links(pages, options, html_options)}"
  #   ret += "&nbsp;&nbsp;" + link_to('下一页', next_url) if pages.current.next
  #   ret
  # end

  # def prev_next_m(pages, options={})
  #   options[:params] = options[:params] || params || {}
  #   prev_url = options[:params].clone
  #   prev_url[:page] = pages.current.previous
  #   next_url = options[:params].clone
  #   next_url[:page] = pages.current.next
  #   ret = ""
  #   ret += link_to(_('Prev'), prev_url, :class => "btn1 rc5 float")  if pages.current.previous
  #   ret += link_to(_('Next'), next_url, :class => "btn1 rc5 rfloat") if pages.current.next
  #   ret += "<div class='clear'></div>"
  #   ret
  # end

#  G2_AUTO_LINK_RE = /
#                  (                       # leading text
#                    <\w+.*?>|             #   leading HTML tag, or
#                    [^(<\w+.*? )=!:'"\/]|           #   leading punctuation, or 
#                    ^                     #   beginning of line
#                  )
#                  (
#                    (?:http[s]?:\/\/)|    # protocol spec, or
#                    (?:www\.)             # www.*
#                  ) 
#                  (
#                    ([~|=+?%\w]+:?[=?&\/.-]?)*    # url segment
#                    \w+[\/]?              # url tail
#                    (?:\#[-\w]*)?            # trailing anchor
#                  )
#                  ([[:punct:]]|\s|<|$)    # trailing text
#                 /x unless const_defined?(:G2_AUTO_LINK_RE)
#  G2_AUTO_LINK_RE = /
#                  (\s|^)
#                  (
#                    (?:http[s]?:\/\/)|    # protocol spec, or
#                    (?:www\.)             # www.*
#                  ) 
#                  (.+?)
#                  (?=\s|$)    # trailing text
#                 /x unless const_defined?(:G2_AUTO_LINK_RE)
        G2_AUTO_LINK_RE = /
                        (                       # leading text
                          <\w+.*?>|             #   leading HTML tag, or
                          [^=!:'"\/]|           #   leading punctuation, or 
                          ^                     #   beginning of line
                        )
                        (
                          (?:http[s]?:\/\/)|    # protocol spec, or
                          (?:www\.)             # www.*
                        ) 
                        (
                          ([~|=+?%\w]+:?[=?&\/.-]?)*    # url segment
                          \w+[\/]?              # url tail
                          (?:\#\w*)?            # trailing anchor
                        )
                        ([[:punct:]]|\s|<|$)    # trailing text
                       /x unless const_defined?(:G2_AUTO_LINK_RE)

  def preview_urls(text, href_options = {})
    extra_options = tag_options(href_options.stringify_keys) || ""
    text.gsub(G2_AUTO_LINK_RE) do
      all, a, b, c, d = $&, $1, $2, $3, $5
      #breakpoint()
      if a =~ /<a\s/i # don't replace URL's that are already linked
        all
      else
        b = "http://www." if b=="www."
        text = b + c
        #text = yield(text) if block_given?
        preview = render(:partial => "previews/#{url_type(text)}", :locals => {:url => text, :extra_options => extra_options, :tailer => d, :header => a})
        %(#{a}#{preview})
      end
    end
  end

  IMAGE_RE = /(\.jpg|\.bmp|\.gif|\.emf|\.jpeg|\.pjpeg|\.pcx|\.pic|\.png|\.tga|\.tiff|\.wmf)(\z|\?|#)/i unless const_defined?(:IMAGE_RE)
  MP3_RE = /(\.mp3)(\z|\?|#)/i unless const_defined?(:MP3_RE)
  AUDIO_RE = /(\.wma|\.wax|\.wav|\.m3u|\.mid|\.midi|\.rmi|\.aif|\.aifc|\.aiff|\.snd)(\z|\?|#)/i unless const_defined?(:AUDIO_RE)
  VIDEO_RE = /(\.rm|\.rmvb|\.wmv|\.wvx|\.avi|\.mpeg|\.mpg|\.mpe|\.m1v|\.mp2|\.mpv2|\.mp2v|\.mpa)(\z|\?|#)/i unless const_defined?(:VIDEO_RE)
  FLASH_RE = /(\.swf|\.spl)(\z|\?|#)/i unless const_defined?(:FLASH_RE)
  def url_type(url)
    if url =~ IMAGE_RE
      :image
    elsif url =~ MP3_RE
      :mp3
    elsif url =~ AUDIO_RE
      :audio
    #elsif url =~ VIDEO_RE
    #  :video
    elsif url =~ FLASH_RE
      :flash
    else
      :html
    end
  end

  # only recognize picture, audio, and link
  def url_type2(url)
    if url =~ IMAGE_RE
      :image
    elsif url =~ MP3_RE
      :mp3
    elsif url =~ AUDIO_RE
      :audio
    else
      :html
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

  def error_notice_on(model, field)
    msg = error_message_on(model, field)
    msg.blank? ? '' : "<span class='notice'>#{msg}</span>"
  end
 
  #2010-10-1 to date type
  def str2date(str)
    a = str.split('-')
    Time.local(a[0],a[1],a[2])
  end
  
  def date_size(count)
    base_size = 11
    max_size = base_size+20
    count = count.to_i
    ret = count + base_size
    ret = max_size if ret > max_size
    ret
  end
  
#-----------------------------------------------------------------------------
protected
  
end
  