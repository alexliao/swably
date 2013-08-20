module ReportsHelper

  # generate link to another report 
  # params: String, Array, Integer, Array, Hash
  def lookup(field_content, row, index, fields, lookups)
    ret = h(field_content)
#    if field_name =~ /.*:(\d+)/
#      lookup_id = $1
#      "<a href='/reports/show/#{lookup_id}?param=#{field_content}'>#{field_content}</a>"
#    else
#      field_content
#    end
    link_field_name = fields[index]
    lookup = lookups[link_field_name]
    if lookup
      param = field_content
      if lookup[:param_field_name]
        i = 0
        fields.each do |field|
          break if fields[i] == lookup[:param_field_name]
          i += 1
        end
        param = row[i]
      end
      ret = "<a href='/reports/#{lookup[:report_id]}?param=#{param}'>#{h(field_content)}</a>"
    end
    
    ret
  end
 
 end
