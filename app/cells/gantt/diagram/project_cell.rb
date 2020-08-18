module Gantt::Diagram
  class ProjectCell < Cell::ViewModel
    self.view_paths = ['plugins/ganttiot/app/cells']

    def show
      render
    end
  end
end
