module Gantt::Diagram
  class ColumnsCell < Cell::ViewModel
    self.view_paths = ['plugins/ganttiot/app/cells']

    # model: query
    # property :available_columns
    # property :columns

    def saved_columns
      Gantt::IssueFieldQuery.new(options[:project], :project, user: User.current)
        .columns
        .map(&:to_s)
      # YAML.load(options[:setting]&.column_names) rescue (columns || []).map(&:name).map(&:to_s)
    end

    def available_columns
      Gantt::IssueFieldQuery.new(options[:project], :project, user: User.current)
        .available_columns
    end

    def show
      render
    end
  end
end
