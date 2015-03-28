class AddInstallsChannelId < ActiveRecord::Migration
  def change
    change_table :installs do |t|
      t.string :channel_id
    end
    add_index :installs, :channel_id
  end
end
