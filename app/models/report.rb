class Report < ActiveRecord::Base
  attr_accessible :category, :lookups, :name, :param_default, :param_name, :sql
end
