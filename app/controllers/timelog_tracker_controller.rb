class TimelogTrackerController < ApplicationController
  unloadable

  before_filter do
    User.current.allowed_to_globally? :log_time, {}
  end

  def cancel
    if !current_tracked_time_entry || current_tracked_time_entry.destroy
      head :ok      
    else
      head 500
    end
  end

  def start
    entry = TrackedTimeEntry.new
    entry.user = User.current
    entry.safe_attributes = params[:timelog_tracker]

    if current_tracked_time_entry
      render status: :bad_request, json: {
        error_code: "tracked_time_entry_already_exists"
      }
    elsif entry.save
      render json: entry
    else
      render status: :bad_request, json: {
        error_code: "save_failed",
        errors: entry.errors
      }
    end
  end

  def commit
    current_tracked_time_entry.safe_attributes = params[:timelog_tracker] if params[:timelog_tracker]

    if current_tracked_time_entry
      time_entry = TimeEntry.new
      time_entry.user = current_tracked_time_entry.user
      time_entry.activity = current_tracked_time_entry.activity
      time_entry.issue = current_tracked_time_entry.issue
      time_entry.spent_on = current_tracked_time_entry.created_at.to_date
      time_entry.hours = ((Time.now - current_tracked_time_entry.created_at) / 1.hour).round(2)

      if time_entry.transaction { time_entry.save && current_tracked_time_entry.destroy }
        render json: time_entry
      else
        render status: :bad_request, json: {
          error_code: "save_failed",
          errors: time_entry.errors
        }
      end
    else
      render status: :bad_request, json: {
        error_code: "tracked_time_entry_doesnt_exist"
      }
    end
  end

    private

    def current_tracked_time_entry
      @current_tracked_time_entry ||= TrackedTimeEntry.find_by_user_id(User.current.id)
    end
end
