module Gantt::Diagram
  class ChatModalCell < Cell::ViewModel
    self.view_paths = ['plugins/ganttiot/app/cells']

    def assigned
      render
    end

    def assigned_close
      render
    end

    def assigned_prolong
      render
    end
  end
end
