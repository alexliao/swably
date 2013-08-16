class AppLocale < ActiveRecord::Base
  belongs_to :app

  def self.add(lang, country, app, name, version_code)
    record = AppLocale.new(:code => [lang,country].compact.join("_"), :app_id => app.id, :name => name, :version_code => version_code)
    record.save
    record
  end

  def self.addUnlessNone(lang, country, app, name, version_code = 0)
    record = AppLocale.find(:first, :conditions => ["code = ? and app_id = ? and version_code >= ?", lang, app.id, version_code])
    unless record
      AppLocale.delete_all("code = '#{lang}' and app_id = #{app.id}")
      record = add(lang, nil, app, name, version_code)
    end
    if country
      record = AppLocale.find(:first, :conditions => ["code = ? and app_id = ? and version_code >= ?", [lang,country].join("_"), app.id, version_code])
      unless record
        AppLocale.delete_all("code = '#{lang}_#{country}' and app_id = #{app.id}")
        record = add(lang, country, app, name, version_code)
      end
    end
    record
  end

  def self.remove(lang, country, app)
    AppLocale.delete_all("code = '#{lang}' and app_id = #{app.id}")
    AppLocale.delete_all("code = '#{lang}_#{country}' and app_id = #{app.id}")
  end
  
  def self.remove_all(app)
    AppLocale.delete_all("app_id = #{app.id}")
  end

end
