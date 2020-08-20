Redmine::Plugin.register :ganttiot do
  name "Gantt plugin"
  author "MaxKagami"
  description "This is a plugin for Redmine"
  version "2.0"
  url "https://github.com/maxkagami/gantt_plugin"
  author_url "https://github.com/maxkagami"
end

require_relative "after_init"
