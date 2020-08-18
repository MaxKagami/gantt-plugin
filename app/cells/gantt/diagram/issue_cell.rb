module Gantt::Diagram
  class IssueCell < Cell::ViewModel
    self.view_paths = ['plugins/ganttiot/app/cells']

    property :issue

    WIDTHS = {
      subject: 100,
      description: 200,
      default: 100
    }.freeze

    def show
      render
    end

    def setting
      options[:setting]
    end

    def calc_w(col, issue)
      widths = setting&.column_settings || {}
      widths[col.name.to_s] || WIDTHS[col.name] || WIDTHS[:default]
    end
  end
end
