module Gantt::Diagram
  class GridCell < Cell::ViewModel
    self.view_paths = ['plugins/ganttiot/app/cells']

    property :project
    property :query
    property :params

    def show
      render
    end
  end
end
