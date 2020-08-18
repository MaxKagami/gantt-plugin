module Gantt::Diagram
  class ProjectIndexCell < Cell::ViewModel
    self.view_paths = ['plugins/ganttiot/app/cells']

    def show
      render
    end
   
    
    def projects
      Project.active.allowed_to(User.current)
    end
  end
end

