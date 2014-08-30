require 'espeo_timelog_tracker/hooks'

Redmine::Plugin.register :espeo_timelog_tracker do
  name 'Espeo Timelog Tracker plugin'
  author 'espeo@jtom.me'
  description 'Adds a timelog tracker below the search field in headerbar, that allows you to quickly add timelog entries just like Toggl !'
  version '1.0.0'
  url 'http://espeo.pl'
  author_url 'http://jtom.me'
end
