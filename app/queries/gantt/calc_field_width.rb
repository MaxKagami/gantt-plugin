module Gantt
  class CalcFieldWidth
    WIDTHS = {
      subject: 100,
      description: 200,
      default: 100
    }.freeze

    def call(col, issue, project = nil)
      widths = GanttIssueSetting.find_by(
        user_id: User.current.id,
        project_id: issue&.project_id || project.id,
        issue_id: nil
      )&.column_settings || {}
      widths[col.to_s] || WIDTHS[col.to_sym] || WIDTHS[:default]
    end
  end
end
