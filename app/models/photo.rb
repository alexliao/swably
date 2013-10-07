require 'RMagick.rb' # force to require RMagick.rb instead of RMagick.so to avoid an error Can't convert string to integer when call ImageList.new
require 'zlib'

class Photo 
  include ModelHelper
  include Magick
  
  #attr_accessor :path
  
  def path
    @path
  end
  
  def initialize(a_path)
    @path = a_path
  end
   
  def mask
#    Photo.ensure_directory(path) + Photo.gen_windows_filename(path) + '_[size].png'
    Photo.ensure_directory(path) + Photo.gen_windows_filename(path) + '_[size]'+Photo::get_postfix(path)
  end
  
  def i16
    Photo.thumbnail(path, :i16)
  end
  def icon
    Photo.thumbnail(path, :icon)
  end
  def square
    Photo.thumbnail(path, :square)
  end
  def big_square
    Photo.thumbnail(path, :big_square)
  end
  def thumbnail
    Photo.thumbnail(path, :thumbnail)
  end
  def small
    Photo.thumbnail(path, :small)
  end
  def medium
    Photo.thumbnail(path, :medium)
  end
  def large
    Photo.thumbnail(path, :large)
  end
  def original
    path
  end
  def by_size(size)
    case
      when size <= 16
        ret = self.i16
      when size > 16 && size <= 32
        ret = self.icon
      when size > 32 && size <= 75
        ret = self.square
      when size <= 75
        ret = Photo.thumbnail(path, size)
      when size > 75 && size <= 100
        ret = self.thumbnail
      when size > 100 && size <= 240
        ret = self.small
      when size > 240 && size <= 500
        ret = self.medium
      when size > 500
        ret = self.large
    end
    ret
  end

  def self.find_owner_only(id, user_id)
    Photo.find_with_condition(id, "photos.user_id = #{user_id}")
  end
  
  def self.find_with_condition(id, conditions = nil, joins = nil)
    begin
      record = Photo.find(id, :joins => joins, :conditions => conditions)
    rescue 
      record = nil
    end
    record
  end


  #get the path of various size of thumbnail picture, if no, created it.
  def self.thumbnail(picture_url, size)
#    thumbnail_url = ensure_directory(picture_url) + thumbnail_name(picture_url, size) + '.png'
    thumbnail_url = ensure_directory(picture_url) + thumbnail_name(picture_url, size) + get_postfix(picture_url)
    thumbnail_path = 'public' + thumbnail_url
    self.create_thumbnail(picture_url, thumbnail_path, size) unless File.exist?(thumbnail_path) #if Rails.env == "production"
    thumbnail_url
  end

  #full text search
  def self.search(query, user_id, limit, offset)
    index_table = FullIndex::match_sql(query, "PhotoIndex")
    find :all, :select => 'photos.*, f.score', :joins => "join (#{index_table}) f on photos.id = f.item_id join entries on entries.id = photos.item_id", :conditions => Entry.privacy_condition(user_id), :order => 'score DESC', :limit => limit, :offset => offset
  end
  def self.search_count(query, user_id)
    index_table = FullIndex::match_sql(query, "PhotoIndex")
    count :joins => "join (#{index_table}) f on photos.id = f.item_id join entries on entries.id = photos.item_id", :conditions => Entry.privacy_condition(user_id)
  end
  
  def flip!
    ret = nil
    pic_path = 'public' + path
    imglst = ImageList.new(pic_path)
  	imglst.each do |img|
  		img.rotate! 90
  		ret = img
  	end
  	# regenerate file name
  	names=path.split(".")
  	path = names[0]+"_"+"."+names[1]
  	pic_path = 'public' + path
    imglst.write("JPG:#{pic_path}")
    return ret.columns, ret.rows, ret.filesize, path
  end

#---------------------------------------------------------------------
private
  # create directory by date if there is not the directory
  def self.ensure_directory(picture_url)
#    url_dir = "/pictures/thumbnails/#{Time.now.strftime('%Y%m%d')}/"
    url_dir = "#{thumbnail_directory}#{gen_sub_dir(picture_url)}/"
    dir = 'public' + url_dir
    Dir.mkdir(dir) if Dir[dir].size == 0
    url_dir
  end

  def self.thumbnail_directory
    "/pictures/thumbnails/"
  end
  
  def self.gen_sub_dir(picture_url)
    # (picture_url.hash.abs/1048576).to_s # value range is 0-1024 by Fixnum/2^20
    # picture_url.hash.to_s[-3,3] # value range is 000-999 # the hash code changed amoung sessions
    Zlib.crc32(picture_url).to_s[-3,3]
  end
  
  def self.thumbnail_name(picture_url, size)
    ret = gen_windows_filename(picture_url) + "_" + size.to_s[0,2] 
  end
  
  #replace unexceptable character with underline, and right trim to 190 for save as Windows file name. (the longest file name in Windows is about 219)
  def self.gen_windows_filename(anystr)
  	limit = 190
  	presize = 100
  	ret = anystr.strip
  	if ret.size > limit 
  		ret = ret[0,presize]  + ret[-(limit-presize)..-1]
  	end
  	ret = ret.gsub(/[\/\\:*?"<>|.\[\]]/,'_')
  end
  
  def self.get_postfix(path)
    pfs = ["gif", "jpg", "jpeg", "bmp", "png", "tif", "tiff", "ico", "pcx", "tga" ]
    a = path.split(".")
    pf = a[-1].downcase
    ret = ".png"
    ret = "."+pf if pfs.include?(pf) 
    return ret
  end
  
  def self.create_thumbnail(picture_url, thumbnail_path, size)
    picture_url = picture_url || ''
    picture_url.strip!
    return if picture_url == '' 
    begin
      picture_url = 'public' + picture_url if picture_url[0,1] == '/' # insite picture
      imglst = ImageList.new(picture_url)
#      format = imglst.size > 1 ? "GIF" : "PNG"
      ret = nil
      case size
        when :i16
      	imglst.each do |img|
      		geom = img.rows < img.columns ? 'x16' : '16'
      		img.change_geometry(geom) { |cols, rows| img.thumbnail!(cols, rows).crop!(CenterGravity, 16, 16, true) }
      		ret = img
      	end
        when :icon
      	imglst.each do |img|
      		geom = img.rows < img.columns ? 'x32' : '32'
      		img.change_geometry(geom) { |cols, rows| img.thumbnail!(cols, rows).crop!(CenterGravity, 32, 32, true) }
      		ret = img
      	end
        when :square
      	imglst.each do |img|
      		geom = img.rows < img.columns ? 'x75' : '75'
      		img.change_geometry(geom) { |cols, rows| img.thumbnail!(cols, rows).crop!(CenterGravity, 75, 75, true) }
      		ret = img
      	end
        when :big_square
      	imglst.each do |img|
      		geom = img.rows < img.columns ? 'x150' : '150'
      		img.change_geometry(geom) { |cols, rows| img.thumbnail!(cols, rows).crop!(CenterGravity, 150, 150, true) }
      		ret = img
      	end
        when :thumbnail
          imglst.each {|img| img.change_geometry('100x100>') { |cols, rows| img.thumbnail! cols, rows }; ret = img; }
        when :small
          imglst.each {|img| img.change_geometry('240x240>') { |cols, rows| img.thumbnail! cols, rows }; ret = img; }
        when :medium
          imglst.each {|img| img.change_geometry('720x720>') { |cols, rows| img.thumbnail! cols, rows }; ret = img; }
        when :large
          imglst.each {|img| img.change_geometry('1280x1280>') { |cols, rows| img.thumbnail! cols, rows }; ret = img; }
        else
          imglst.each {|img| img.change_geometry("#{size}x#{size}>") { |cols, rows| img.thumbnail! cols, rows }; ret = img; }
      end
#      imglst.write("#{format}:#{thumbnail_path}")
      imglst.write("#{thumbnail_path}")
    rescue Exception => e
puts e
    #  ActiveRecord::Base.logger.error("#{Time.now.short_time} Custom log : Exception in Photo.create_thumbnail " + e) # not works
    end
      return ret.columns, ret.rows, ret.filesize if ret
  end
end
