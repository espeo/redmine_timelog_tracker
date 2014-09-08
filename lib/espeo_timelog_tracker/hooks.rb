# This is unfortunately needed to allow
# the use of following methods in the _timelog_tracker.html view:
# - #activity_collection_for_select_options
Rails.application.config.to_prepare do
  ApplicationController.class_eval do
    helper :timelog
  end
end

module EspeoTimelogTracker
  class Hooks < Redmine::Hook::ViewListener

    # Add timelog.js to <head></head> of every page.
    def view_layouts_base_body_bottom(context = {})
      return unless User.current.logged?

      context[:controller].send(:render_to_string, {
        :partial => "timelog_tracker",
        :locals => context.merge({
          current_tracked_time_entry: TrackedTimeEntry.find_by_user_id(User.current.id)
        })
      })
    end

  end
end
