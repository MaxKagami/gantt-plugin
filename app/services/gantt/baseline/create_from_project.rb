module Gantt::Baseline
  class CreateFromProject
    include Dry::Transaction

    step :create

    private

    def create(project:, params: {})
      # from baseline controller #create
      options = { name: params[:name] } if params.key?(:name)
      baseline = prepare_baseline(project, options || {})
      unless baseline&.save(validate: false) &&
             baseline&.copy(project, only: %w[versions issues], with_time_entries: false)
        return Failure(:error_saving_baseline)
      end

      # Easyredmine copies time on {copy_issues}
      baseline.time_entries.destroy_all

      # Prevent relations pointing to the baseline
      all_issue_ids = baseline.issues.ids

      from_id_sql = IssueRelation.arel_table[:issue_from_id].in(all_issue_ids)
      to_id_sql = IssueRelation.arel_table[:issue_to_id].in(all_issue_ids)

      IssueRelation.where(from_id_sql.or(to_id_sql)).delete_all
      Success(baseline)
    end

    # baseline_controller
    def prepare_baseline(project, options = {})
      return unless project

      baseline = Project.copy_from(project.id)
      baseline.status = Project::STATUS_ARCHIVED
      # Without this hack it disables a modules on original project see http://www.redmine.org/issues/20512 for details
      baseline.enabled_modules = []
      baseline.enabled_module_names = project.enabled_module_names
      time = Time.zone.now
      baseline.name = options[:name] ||
                      format(
                        '%<time>s %<name>s',
                        time: ::I18n.l(time, format: '%d-%m-%y %H:%M'),
                        name: project.name
                      )
      baseline.identifier = options[:name]&.parameterize || project.identifier + '_' + Time.now.strftime('%Y%m%d%H%M%S')
      baseline.easy_baseline_for_id = project.id
      baseline.parent = Gantt::Baseline.baseline_root_project
      # Project.copy_from change customized so CV are not copyied but moved
      # Already done in easyredmine
      baseline.custom_values = project.custom_values.map do |val|
        val.dup.tap { |v| v.customized = baseline }
      end
      baseline.update(zaoeps_baseline_start_date: time.to_date)
      baseline
    end
  end
end
