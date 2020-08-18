module Gantt
  class CalcWorktimeEntries
    LEVELS = {
      non_started: %I[before late],
      in_work: %I[in_work two_days work_late late_critical],
      done: [:done]
    }.freeze
    STATUSES = {
      before: 'не начата до даты начала',
      late: 'не начата после даты начала',
      in_work: 'в работе',
      two_days: 'в работе 2 дня до завершения (от 7 дней задача)',
      work_late: 'просрочена в пределах 3х дней',
      late_critical: 'просрочена больше 3х дней',
      done: 'завершена'
    }.freeze

    def initialize(issue, baseline = nil)
      @issue = issue
      @baseline = baseline
    end

    def call
      # p intervals(@issue).worktime
      # worktime
      # ksg
      indicator
      # self
    end

    private

    def worktime_entries
      intervals(@issue)
        .worktime
        .sort_by(&:start)
        .map { |val| Gantt::WorkItemStruct.new(val.to_width) }
    end

    def ksg_entries(base)
      intervals(@issue)
        .ksg(base)
        .map { |val| Gantt::WorkItemStruct.new(val.to_width) }
    end

    def ksg
      ksg_entries(@baseline)
    end

    def worktime
      worktime_entries
    end

    def indicator
      ind = issue_status
      sub = issue_sub(ind)
      { ind => sub }
    end

    def issue_sub(ind)
      return :done if ind == :done

      return :before if ind == :non_started

      :in_work
    end

    def issue_status
      int = intervals(@issue)
      if @issue.status_id == 1 && (int.worktime.empty? || int.worktime.all? { |i| i.status_id == 1 })
        return :non_started
      end

      return :done if @issue.status.is_closed?

      :in_work
    end

    def intervals(issue)
      @intervals ||= Gantt::WorkIntervalsQuery.new(issue)
    end
  end
end
