module Gantt::Diagram
  class ChartCell < Cell::ViewModel
    self.view_paths = ['plugins/ganttiot/app/cells']

    # property :project
    # property :query
    # property :params

    def ids
      @ids ||= model.map(&:project).compact.map(&:id)
    end

    def projects
      @projects ||= ids.each_with_object({}) do |id, obj|
        prj = Project.find(id)
        obj.merge!(Project.where('lft >= :lft and rgt <= :rgt', lft: prj.lft, rgt: prj.rgt).group_by(&:id))
      end
    end

    def issues
      @issues ||= Issue.where(project_id: projects.keys).group_by(&:id)
    end

    def start
      return local_plan.flatten.map(&:start_date).min unless baseline

      baseline.issues.pluck(:start_date).min
    end

    def stop
      return local_plan.flatten.map(&:due_date).compact.max || Time.zone.now unless context[:baseline]

      stop = baseline.issues.pluck(:due_date).compact.max
      stop = Time.zone.now if baseline.issues.where(due_date: nil).exists? && Time.zone.now > stop
      stop
    end

    def show
      render
    end

    private

    def local_plan
      return model.issue.project.issues unless ids.present?

      issues.values
    end

    def baseline
      context[:baseline] ||= select_plan
    end

    def select_plan
      return unless ids.present?

      Project.where(easy_baseline_for_id: ids).order('created_on desc').first
    end
  end
end
