class ExcludeEmail < ActiveRecord::Base

  def self.add(email)
    record = ExcludeEmail.new(:email => email)
    record.save
    record
  end

  def self.remove(email)
    ExcludeEmail.delete_all("email = '#{email}'")
  end
  
end
