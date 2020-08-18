module Gantt::Diagram
  class ChartItemCell < Cell::ViewModel
    self.view_paths = ['plugins/ganttiot/app/cells']

    property :project
    property :children
    property :issues

    def show
      render
    end
  end
end
