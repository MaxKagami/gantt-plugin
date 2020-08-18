root_dir = Pathname.new(File.dirname(__FILE__))
app_dir = root_dir.join('app')
lib_dir = root_dir.join('lib')
ActiveSupport::Deprecation.behavior = :log
ActiveSupport::Dependencies.autoload_paths << app_dir.join('models')
ActiveSupport::Dependencies.autoload_paths << app_dir.join('queries')
ActiveSupport::Dependencies.autoload_paths << app_dir.join('services')
ActiveSupport::Dependencies.autoload_paths << app_dir.join('forms')
ActiveSupport::Dependencies.autoload_paths << app_dir.join('structs')
ActiveSupport::Dependencies.autoload_paths << app_dir.join('cells')

Dir[lib_dir.join('ganttiot/redmine_patch/**/*.rb')].each { |file| require_dependency file }
Dir[lib_dir.join('ganttiot/*.rb')].each { |file| require_dependency file }

Rails.application.config.assets.precompile += %w[gantt.css gantt.js]

Rails.application.configure do
  config.reform.enable_active_model_builder_methods = true
  config.reform.validations = :dry
end

Redmine::MenuManager.map :top_menu do |menu|
  menu.push( :global_gantt,
             { controller: 'gantt', action: 'index' },
             caption: :label_gantt,
             # after: :documents,
             html: { class: 'icon icon-stats' },
             if: proc { User.current.allowed_to_globally?(:view_global_gantt) }
  )
end

Redmine::MenuManager.map :project_menu do |menu|
  menu.push( :project_gantt,
             { controller: 'gantt', action: 'index', id: nil },
             param: :project_id,
             caption: :button_project_menu_gantt,
             if: proc { |p| User.current.allowed_to?(:view_gantt, p) }
  )
end

RedmineExtensions::Reloader.to_prepare do
  # This access control is used by 4 plugins
  # Logic is also copied on easy_resource_base
  #
  # easy_gantt
  # easy_gantt_pro
  # easy_gantt_resources
  # easy_resource_base
  # easy_scheduler
  #
  Redmine::AccessControl.map do |map|
    map.project_module :ganttiot do |pmap|
      # View project level
      pmap.permission(:view_gantt, {
                        gantt: %i[index show],
                        baseline: %i[index show create]
                        # gantt_settings: %I[index create],
                        # easy_gantt: %i[index issues projects issues_up issues_down toggle_dates
                        #                issues_open issues_close motivation_report create_motivation_report],
                        # easy_gantt_pro: %i[lowest_progress_tasks cashflow_data motivation_report
                        #                    create_motivation_report],
                        # easy_gantt_resources: %i[index project_data users_sums projects_sums allocated_issues
                        #                          issue_up issue_down toggle_dates motivation_report
                        #                          create_motivation_report]
                        # easy_gantt_reservations: [:index]
                      }, read: true, require: :member)
      pmap.permission(:view_global_gantt, {
                        gantt: %i[index show],
                        baseline: %i[index show create]
                        # gantt_settings: %I[index create],
                        # easy_gantt: %i[index issues projects issues_up issues_down toggle_dates
                        #                issues_open issues_close motivation_report create_motivation_report],
                        # easy_gantt_pro: %i[lowest_progress_tasks cashflow_data motivation_report
                        #                    create_motivation_report],
                        # easy_gantt_resources: %i[index project_data users_sums projects_sums allocated_issues
                        #                          issue_up issue_down toggle_dates motivation_report
                        #                          create_motivation_report]
                        # easy_gantt_reservations: [:index]
                      }, read: true, global: true)
    end
  end
end
