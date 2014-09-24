(function($, undefined){

  var REDMINE_ORIGIN = location.origin,

      noop = function(){};

  var TimelogTracker = function(){
    var self = this;

    this.$container = $("#timelog_tracker");
    this.$inputs = this.$container.find("#timelog_tracker_activity_id, #timelog_tracker_issue_id");
    this.$activity = this.$container.find("#timelog_tracker_activity_id");
    this.$issue = this.$container.find("#timelog_tracker_issue_id");

    $(document).ready(function(){
      self.init();
    });
  };

  TimelogTracker.prototype.init = function TimelogTracker__init() {
    var self = this;

    this.$container.find("form").submit(function TimelogTracker__submitForm(event){
      event.preventDefault();
      if (self.currentTimeEntry) {
        self.commit();
      } else {
        self.start();
      }
    });

    this.$container.find(".cancel-button").click(function TimelogTracker__clickCancelButton(event){
      event.preventDefault();

      self.cancel(function(){
        setTimeout(function(){
          self.$container.find("#timelog_tracker_issue_id").focus();
        });
      });
    });

    this.$container.find(".start-button").click(function TimelogTracker__clickStartButton(event){
      event.preventDefault();

      self.start(function(){
        setTimeout(function(){
          self.$container.find(".commit-button").focus();
        });
      });
    });

    this.$container.find(".commit-button").click(function TimelogTracker__clickCommitButton(event){
      event.preventDefault();

      self.commit(function(){
        setTimeout(function(){
          self.$container.find("#timelog_tracker_issue_id").focus();
        });
      });
    });

    this.$container.find(".commit-and-edit-button").click(function TimelogTracker__clickCommitAndEditButton(event){
      event.preventDefault();

      self.commit(function(timeEntry){
        self.editTimeEntry(timeEntry.id);
        setTimeout(function(){
          self.$container.find("#timelog_tracker_issue_id").focus();
        });
      });
    });

    this.$container.find("#timelog_tracker_activity_id").change(function(){
      var activityId = $(this).val();
      if (activityId) {
        sessionStorage.setItem("timelog_tracker.default_activity_id", activityId);
      }
    });

    this._triggerUpdate = $.debounce(300, function(){
      self.update();
    });

    this.$inputs.change(function(){
      self.rerender();

      if (self.currentTimeEntry) {
        self._triggerUpdate();
      }
    });

    self.rerender();
    this.$container.insertAfter("#header h1").show();
  };

  TimelogTracker.prototype.rerender = function() {
    this.$container.toggleClass("tracking", !!this.currentTimeEntry);
    this.$inputs.prop("required", !!this.currentTimeEntry);

    this.isFormValid = true;
    var $invalidInputs = this.$inputs.filter(function(){
      return $(this).prop("required") && !$(this).val();
    });
    if ($invalidInputs.length > 0) {
      this.isFormValid = false;
    }

    this.$container.find("button, input[type=submit]").prop("disabled", !this.isFormValid);
  };

  TimelogTracker.prototype._setCurrentTrackedTimeEntry = function(timeEntry) {
    var self = this;

    this.currentTimeEntry = timeEntry;

    if (this.__updateTimeInterval) {
      clearInterval(this.__updateTimeInterval);
      delete this.__updateTimeInterval;
      $("#timelog_tracker_time").html("");
    }

    if (timeEntry) {
      timeEntry.created_at_date = new Date(timeEntry.created_at);

      this.$container.find("#timelog_tracker_activity_id").val( timeEntry.activity_id );
      this.$container.find("#timelog_tracker_issue_id").val( timeEntry.issue_id );
      this.__updateTimeInterval = setInterval(function(){
        self._updateTime();
      }, 1000);
      self._updateTime();
    } else {
      $("#timelog_tracker_issue_name").html("");
      this.$inputs.val("");

      var activityId = sessionStorage.getItem("timelog_tracker.default_activity_id")
      if (activityId) {
        this.$container.find("#timelog_tracker_activity_id").val(activityId);
      }
    }

    this.rerender();
  };

  TimelogTracker.prototype._updateTime = function() {
    var currentDate = new Date(),
        timeDuration = ~~((currentDate - this.currentTimeEntry.created_at_date) / 1000),
        hours = ~~(timeDuration / 3600),
        minutes = ~~((timeDuration - hours * 3600) / 60),
        seconds = (timeDuration - hours * 3600 - minutes * 60),

        time = [hours, "h ", minutes, "m ", seconds, "s"].join("");

    $("#timelog_tracker_time").html(time);
  };

  TimelogTracker.prototype.handleAjaxError = function(jqXHR) {
    var data;
    try {
      data = JSON.parse(jqXHR.responseText);
    } catch(e) {
    }

    if (typeof data === "object" && data.errors) {
      alert("Server returned error:" + data.errors.join("\n"));
    }
  };

  TimelogTracker.prototype.start = function TimelogTracker__start(onSuccess, onError) {
    var self = this;

    return $.ajax({
      url: REDMINE_ORIGIN + "/timelog_tracker/start",
      type: 'POST',
      data: this.$container.find("form").serialize()
    }).done(function(data){
      (onSuccess || noop)(data.tracked_time_entry);

      self._setCurrentTrackedTimeEntry(data.tracked_time_entry);
    }).fail(onError || self.handleAjaxError);
  };

  TimelogTracker.prototype.update = function TimelogTracker__start(onSuccess, onError) {
    console.debug('TimelogTracker.update()');
    var self = this;

    return $.ajax({
      url: REDMINE_ORIGIN + "/timelog_tracker",
      type: 'PATCH',
      data: this.$container.find("form").serialize()
    }).done(function(data){
      (onSuccess || noop)(data.tracked_time_entry);

      self._setCurrentTrackedTimeEntry(data.tracked_time_entry);
    }).fail(onError || self.handleAjaxError);
  };

  TimelogTracker.prototype.cancel = function TimelogTracker__cancel(onSuccess, onError) {
    var self = this;

    return $.ajax({
      url: REDMINE_ORIGIN + "/timelog_tracker/cancel",
      type: 'POST',
      data: this.$container.find("form").serialize()
    }).done(function(data){
      (onSuccess || noop)();

      self._setCurrentTrackedTimeEntry(null);
    }).fail(onError || self.handleAjaxError);
  };

  TimelogTracker.prototype.commit = function TimelogTracker__commit(onSuccess, onError) {
    var self = this;

    if (!this.isFormValid) {
      return false;
    }

    return $.ajax({
      url: REDMINE_ORIGIN + "/timelog_tracker/commit",
      type: 'POST',
      data: this.$container.find("form").serialize()
    }).done(function(data){
      (onSuccess || noop)(data.time_entry);

      self._setCurrentTrackedTimeEntry(null);
    }).fail(onError || self.handleAjaxError);
  };

  TimelogTracker.prototype.editTimeEntry = function(timeEntryId) {
    var url = REDMINE_ORIGIN + "/time_entries/" + timeEntryId + "/edit";

    window.open(url);
  };

  TimelogTracker.prototype.setActivities = function(activities) {
    var currentActivityId = +this.$activity.val();

    this.$activity.html(activities.map(function(activity){
      return "<option value='"+ activity.id +"'>"+ activity.name +"</option>";
    }).join(""));
    this.$activity.val(currentActivityId);
  };

  window.timelogTracker = new TimelogTracker();

})(jQuery);
