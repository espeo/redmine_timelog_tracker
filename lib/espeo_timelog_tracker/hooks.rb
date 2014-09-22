module EspeoTimelogTracker
  class Hooks < Redmine::Hook::ViewListener
    # Add timelog.js to <head></head> of every page.
    def view_layouts_base_body_bottom(context = {})
      return unless User.current.logged?
      return unless User.current.allowed_to?(:log_time, context[:project], {global: context[:project].nil?})

      context[:controller].send(:render_to_string, {
        :partial => "timelog_tracker",
        :locals => context.merge({
          current_tracked_time_entry: TrackedTimeEntry.find_by_user_id(User.current.id),
          activity_collection_for_timelog_tracker_select_options: activity_collection_for_select_options(nil, @project)
        })
      })
    end

    private

      # Returns a collection of activities for a select field.  time_entry
      # is optional and will be used to check if the selected TimeEntryActivity
      # is active.
      # 
      # Source: TimelogHelper (app/helpers/timelog_helper.rb)
      def activity_collection_for_select_options(time_entry=nil, project=nil)
        project ||= @project
        if project.nil?
          activities = TimeEntryActivity.shared.active
        else
          activities = project.activities
        end

        collection = []
        if time_entry && time_entry.activity && !time_entry.activity.active?
          collection << [ "--- #{l(:actionview_instancetag_blank_option)} ---", '' ]
        else
          collection << [ "--- #{l(:actionview_instancetag_blank_option)} ---", '' ] unless activities.detect(&:is_default)
        end
        activities.each { |a| collection << [a.name, a.id] }
        collection
      end

  end
end
