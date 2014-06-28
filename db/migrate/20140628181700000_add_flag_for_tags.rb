class AddFlagForTags < ActiveRecord::Migration
  def change
  	add_column :tags, :flag, :integer
  end
end
