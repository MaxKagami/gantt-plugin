module Gantt::Diagram
  class BuildChartLineCell < Cell::ViewModel
    self.view_paths = ['plugins/ganttiot/app/cells']

    property :project
    property :issue

    def worktime_entries
      intervals(issue)
        .worktime
        .sort_by(&:start)
        .map { |val| Gantt::WorkItemStruct.new(val.to_width) }
    end

    def ksg_entries(base)
      intervals(issue)
        .ksg(base)
        .map { |val| Gantt::WorkItemStruct.new(val.to_width) }
    end

    def show
      render
    end

    def worktime_size
      Gantt::WorkItemStruct.new(width: (intervals(issue).worktime.map(&:stop).compact.map(&:to_i).max || 0) -
                                  (intervals(issue).worktime.map(&:start).compact.map(&:to_i).min || 0),
                                start: (intervals(issue).worktime.map(&:start).compact.map(&:to_i).min || 0))
    end

    private

    def zoom
      options[:query]&.period_settings.yield_self { |q| q || {} }[:period_zoom] || 'month'
    end

    def intervals(issue)
      @intervals ||= Gantt::WorkIntervalsQuery.new(issue)
    end
  end
end
