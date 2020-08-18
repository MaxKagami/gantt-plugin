module Gantt::Diagram
  class ExcelImportCell < Cell::ViewModel
    self.view_paths = ['plugins/ganttiot/app/cells']

    def show
      render
    end

    def preview
      render
    end
  end
end
