class AddTagsCountForApps < ActiveRecord::Migration
  def change
  	add_column :apps, :tags_count, :integer
  end
end
