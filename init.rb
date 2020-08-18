Redmine::Plugin.register :ganttiot do
  name 'IOT Gantt plugin'
  author 'afa'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'https://github.com/afa/ganttiot'
  author_url 'https://github.com/afa'
end

require_relative 'after_init'
