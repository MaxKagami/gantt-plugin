module Gantt
  class WorkIntervalsQuery
    attr_reader :project, :issue, :start_baselines, :stop_baselines

    def initialize(issue)
      @issue = issue
      @start_baselines = {}
      @stop_baselines = {}
      @project = issue.project
      # @project = project
    end

    def call; end

    def worktime
      query_select_param(:intervals_sql, [issue.id]).to_a.map do |row|
        Gantt::IssueStatusIntervalStruct.new row
      end
    end

    def ksg(base)
      return [] unless issue && base

      dst = EasyBaselineSource.find_by(baseline_id: base.id, source_id: issue.id, relation_type: 'Issue')&.destination
      return [] unless dst

      [Gantt::IssueStatusIntervalStruct.new(
        start: dst.start_date.to_time,
        stop: due(dst.due_date || Time.zone.now),
        issue_id: issue.id,
        status_id: 1
      )]
    end

    private

    def due(date)
      Time.new(date.year, date.month, date.day, 24)
    end

    def query_select_param(method_sym, param)
      sql = method(method_sym).call(param)
      return [] if sql.nil?

      ActiveRecord::Base.connection_pool.with_connection { |conn| conn.exec_query(sql) }
    end

    def query_select(method_sym)
      sql = method(method_sym).call
      return [] if sql.nil?

      ActiveRecord::Base.connection_pool.with_connection { |conn| conn.exec_query(sql) }
    end

    def intervals_sql(issue_id)
      <<~SQL
        with status_intervals(start, stop, issue_id, status_id) as (
          select
            journals.created_on start,
            lead(journals.created_on, 1) over (partition by journals.journalized_id order by journals.created_on) stop,
            journals.journalized_id issue_id,
            cast(journal_details.value as integer) status_id
          from journal_details
          inner join journals on journals.id = journal_details.journal_id
          where journal_details.property = 'attr' and journal_details.prop_key = 'status_id'
            and journals.journalized_type = 'Issue'
            and journals.journalized_id in (#{issue_id.join(',')})
        ),
        status_issues(start, stop, issue_id, status_id) as (
          select
            start_date start,
            due_date stop,
            id issue_id,
            status_id status_id
          from issues
          where id not in (select distinct issue_id from status_intervals) and id in (#{issue_id.join(',')})
        ),
        status_days(start, stop, issue_id, status_id) as (
          select
            status_intervals.start start,
            coalesce(status_intervals.stop) stop,
            status_intervals.issue_id issue_id,
            status_intervals.status_id status_id
          from status_intervals
          union
          select
            cast(status_issues.start as date) start,
            coalesce(cast(status_issues.stop as date)) stop,
            status_issues.issue_id issue_id,
            status_issues.status_id status_id
          from status_issues
        )
        select
          start,
          stop,
          issue_id,
          status_id
        from status_days
      SQL
    end
  end
end
