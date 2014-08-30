class CreateTrackedTimeEntries < ActiveRecord::Migration
  def change
    create_table :tracked_time_entries do |t|
      t.references :user, :null => false
      t.references :issue
      t.references :activity
      t.datetime :created_at, :null => false
    end
    add_index :tracked_time_entries, :user_id
    add_index :tracked_time_entries, :issue_id
    add_index :tracked_time_entries, :activity_id
  end
end
