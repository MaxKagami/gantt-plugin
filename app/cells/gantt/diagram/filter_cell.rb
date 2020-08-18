module Gantt::Diagram
  class FilterCell < Cell::ViewModel
    self.view_paths = ['plugins/ganttiot/app/cells']

    attr_reader :loader, :project

    # property :issue

    def show
      @project = Project.find(model[:project_id])
      render
    end

    def apply
      @loader = Gantt::QueryLoadQuery.new(params: model)
      @project = @loader.load_project
      @loader.apply_params

      @loader.load_baseline
      @loader.load_query
      render(:apply)
    end

    def values
      q = Gantt::IssueFieldQuery.new(@project, model[:name], user: User.current)
      q.values
    end
  end
end
