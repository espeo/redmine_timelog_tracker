class TrackedTimeEntry < ActiveRecord::Base
  include Redmine::SafeAttributes
  
  unloadable

  belongs_to :issue
  belongs_to :user
  belongs_to :activity, :class_name => 'TimeEntryActivity', :foreign_key => 'activity_id'

  validates_presence_of :user_id

  safe_attributes 'issue_id', 'activity_id'
end
