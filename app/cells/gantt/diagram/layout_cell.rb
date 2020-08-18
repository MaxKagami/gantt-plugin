module Gantt::Diagram
  class LayoutCell < Cell::ViewModel
    self.view_paths = ['plugins/ganttiot/app/cells']

    property :project
    property :query
    property :baseline
    property :params
    property :widthes

    def show
      render
    end

    def setting
      GanttIssueSetting.find_by(user_id: User.current&.id, project_id: project.id, issue_id: nil) ||
        GanttIssueSetting.create(user_id: User.current&.id, project_id: project.id, issue_id: nil)
    end

    def projects_tree
      Gantt::ProjectTreeQuery.new(project: project).call
    end

    def calc
      setting.column_settings['grid_size'] || 400
    end
  end
end
