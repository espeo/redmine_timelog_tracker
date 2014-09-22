module EspeoTimelogTracker
  class Hooks < Redmine::Hook::ViewListener

    # Add timelog.js to <head></head> of every page.
    def view_layouts_base_body_bottom(context = {})
      return unless User.current.logged?
      return unless User.current.allowed_to?(:log_time, context[:project], {global: context[:project].nil?})

      # This is unfortunately needed to allow
      # the use of following methods in the _timelog_tracker.html view:
      # - #activity_collection_for_select_options
      unless context[:controller].view_context.respond_to?(:activity_collection_for_select_options)
        context[:controller].view_context.extend TimelogHelper
      end

      context[:controller].send(:render_to_string, {
        :partial => "timelog_tracker",
        :locals => context.merge({
          current_tracked_time_entry: TrackedTimeEntry.find_by_user_id(User.current.id)
        })
      })
    end

  end
end
