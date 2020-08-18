module Gantt::Diagram
  class HeaderCell < Cell::ViewModel
    FILTERABLE = %i[assigned_to project status author].freeze

    attr_reader :start, :stop
    self.view_paths = ['plugins/ganttiot/app/cells']

    MULT = {
      'week' => 1_100,
      'decade' => 1_540,
      'month' => 4_400,
      'quarter' => 13_200,
      'half' => 26_400,
      'year' => 52_800,
      'project' => 158_400
    }.freeze

    property :columns
    property :available_columns
    property :period_settings
    property :project

    WIDTHS = {
      subject: 100,
      description: 200,
      default: 100
    }.freeze

    def calc_w(col, _issue = nil)
      widths = GanttIssueSetting.find_by(
        user_id: User.current.id,
        project_id: project.id,
        issue_id: nil
      )&.column_settings || {}
      widths[col] || WIDTHS[col.to_sym] || WIDTHS[:default]
    end

    def saved_columns
      YAML.load(options[:setting]&.column_names) rescue (columns || []).map(&:name).map(&:to_s)
    end

    def show
      render
    end

    def grid
      render :grid
    end

    def chart(start, stop)
      @start = start
      @stop = stop
      @width = calc_widths(start, stop)
      render :chart
    end

    def calc_widths(start, stop)
      from = start.to_date
      to = stop.to_date
      (from..to).each_with_object({}) do |day, obj|
        obj[day] = case zoom
                   when 'week'
                     { top: (day - from) / 7, bottom: day - from }
                   when 'decade'
                   when 'month'
                   when 'quarter'
                   when 'half'
                   when 'year'
                   when 'project'
                   else
                     nil
        end
      end
    end

    def def_start
      period_settings[:period_start_date]
    end

    def def_stop
      period_settings[:period_end_date]
    end

    def zoom
      period_settings&.dig(:period_zoom) || 'month'
    end

    def chart_headers(start = nil, stop = nil)
      rng = stop.to_time - start.to_time
      elemsize = MULT[zoom]
      count = (rng.to_f / elemsize).ceil
      count.times.each_with_object([]) do |idx, arr|
        dt = Time.at(start.to_time.to_i + elemsize * idx).to_date
        arr << [dt, dt.day]
      end.uniq
    end

    def header_width
      86_400 / MULT['month']
    end

    def avail?(col)
      set = GanttIssueSetting.find_by(project_id: project.id, user_id: User.current.id, issue: nil)
      return false unless set

      q = JSON.parse(set.query_params || '{}').fetch(col, nil)
      return false unless q

      true
    end

    private

    def month_size(date)
    end

    def project_size(date)
    end
  end
end
