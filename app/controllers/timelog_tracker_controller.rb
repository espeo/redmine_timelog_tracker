class TimelogTrackerController < ApplicationController
  unloadable

  before_filter :find_project, only: :autocomplete_issues

  before_filter do
    User.current.allowed_to_globally? :log_time, {}
  end

  def autocomplete_issues
    @issues = []
    q = (params[:q] || params[:term]).to_s.strip
    if q.present?
      scope = (@project.nil? ? Issue : @project.issues).visible
      if q.match(/\A#?(\d+)\z/)
        @issues << scope.find_by_id($1.to_i)
      end
      @issues += scope.where("LOWER(#{Issue.table_name}.subject) LIKE LOWER(?)", "%#{q}%").order("#{Issue.table_name}.id DESC").limit(10).all
      @issues.compact!
    end

    json_data = @issues.map do |issue|
      {
        id: issue.id,
        label: "[#{issue.project.name}] #{issue.tracker} ##{issue.id}: #{issue.subject.to_s.truncate(60)}",
        value: issue.id,
        project: ({
          id: issue.project.id,
          activities: issue.project.activities.map do |activity|
            {
              id: activity.id,
              name: activity.name,
            }
          end
        } if issue.project)
      }
    end

    render :json => json_data
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
        errors: entry.errors.full_messages
      }
    end
  end

  def update
    if current_tracked_time_entry
      current_tracked_time_entry.safe_attributes = params[:timelog_tracker] if params[:timelog_tracker]
      current_tracked_time_entry.save

      render json: current_tracked_time_entry
    else
      render status: :bad_request, json: {
        error_code: "tracked_time_entry_doesnt_exist"
      }
    end
  end

  def commit
    if current_tracked_time_entry
      current_tracked_time_entry.safe_attributes = params[:timelog_tracker] if params[:timelog_tracker]

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
          errors: time_entry.errors.full_messages
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

    def find_project
      if params[:project_id].present?
        @project = Project.find(params[:project_id])
      end
    rescue ActiveRecord::RecordNotFound
      render_404
    end
end
