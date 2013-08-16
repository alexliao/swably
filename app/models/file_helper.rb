module FileHelper

  # create directory by date if there is not the directory
  def get_picture_dir
    url_dir = "/pictures/#{Time.now.strftime('%Y%m%d')}"
    dir = "public" + url_dir
    Dir.mkdir(dir) if Dir[dir].size == 0
    url_dir
  end

  # create directory by date if there is not the directory
  def get_apk_dir
    url_dir = "/apks/#{Time.now.strftime('%Y%m%d')}"
    dir = "public" + url_dir
    Dir.mkdir(dir) if Dir[dir].size == 0
    url_dir
  end

private
  def sanitize_filename(value)
      # get only the filename, not the whole path
      just_filename = value.gsub(/^.*(\\|\/)/, '')
      # NOTE: File.basename doesn't work right with Windows paths on Unix
      # INCORRECT: just_filename = File.basename(value.gsub('\\\\', '/')) 

        # Finally, replace all non alphanumeric, underscore or periods with underscore
      return just_filename.gsub(/[^\w\.\-]/,'_') 
  end
  
  def get_suffix(file_name)
    suffix = file_name.split('.')[-1]
    suffix = "" if suffix == file_name
    suffix
  end
  
  def sub_type(io)
    ret = io.content_type.split("/")[1].strip
    ret.sub("pjpeg","jpg")
    ret.sub("jpeg","jpg")
  end

  def save_file(upload_field, dir, save_name)
    #save_name = ((Time.now-Time.gm(2011))*1000).to_i.to_s
    postfix = get_suffix(upload_field.original_filename)
    postfix = sub_type(upload_field) if postfix == ''
    #file_name = sanitize_filename(upload_field.original_filename).split('.')[0]
    save_name = "#{save_name}.#{postfix}"
    save_url = "#{dir}/#{save_name}"
    save_path = "public#{save_url}"
#    if upload_field.methods.include?("local_path") and upload_field.local_path
#      #system "chmod", "644", upload_field.local_path
#      FileUtils.copy upload_field.local_path, save_path
#    else
      File.open(save_path, "wb") { |f| f.write(upload_field.read) }
#    end
    return save_url, save_path
  end
end