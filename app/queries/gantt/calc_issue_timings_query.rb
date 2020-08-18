module Gantt
  class CalcIssueTimingsQuery
    attr_reader :issue

    def initialize(issue:)
      @issue = issue
    end

    def call
      calc
    end

    def issue_diff_start
      calc_diff_start(issue.start_date, calc_real_start)
    end

    def issue_diff_end
      calc_diff_end(issue.due_date, calc_real_end)
    end

    def issue_diff_duration
      calc_diff_duration(issue.start_date, issue.due_date, calc_real_start, calc_real_end)
    end

    private

    def calc
      data = OpenStruct.new
      data.real_start = calc_real_start
      data.real_end = calc_real_end
      data.issue_start_date = issue.start_date
      data.issue_due_date = issue.due_date
      data.start_date = planned_start
      data.due_date = planned_end
      data.issue_diff_start = calc_diff_start(data.issue_start_date, data.real_start)
      data.issue_diff_end = calc_diff_end(data.issue_due_date, data.real_end)
      data.issue_diff_duration = calc_diff_duration(
        data.issue_start_date,
        data.issue_due_date,
        data.real_start,
        data.real_end
      )
      data.diff_start = calc_diff_start(data.start_date, data.real_start)
      data.diff_end = calc_diff_end(data.due_date, data.real_end)
      data.diff_duration = calc_diff_duration(data.start_date, data.due_date, data.real_start, data.real_end)
      data
    end

    def calc_real_start
      issue.journals.flat_map(&:details).select do |x|
        x.prop_key == 'status_id' &&
          x.old_value.to_i.in?(IssueStatus.where(is_closed: false).ids) &&
          x.value.to_i.in?(IssueStatus.where(is_closed: false).ids)
      end.first&.journal&.created_on || Time.zone.today
    end

    def calc_real_end
      if issue.closed?
        issue.journals.flat_map(&:details)
          .select { |x| x.prop_key == 'status_id' && x.value.to_i.in?(IssueStatus.where(is_closed: true).ids) }
          .last&.journal&.created_on
      else
        Time.zone.today
      end
    end

    def planned_start
      field = IssueCustomField.find_by(name: I18n.t('baselines.custom_fields.name_plan_start_date'))
      return nil unless field

      val = issue.custom_values.find_by(custom_field_id: field.id)
      return nil unless val

      Date.parse(val.value) rescue nil
    end

    def planned_end
      field = IssueCustomField.find_by(name: I18n.t('baselines.custom_fields.name_plan_end_date'))
      return nil unless field

      val = issue.custom_values.find_by(custom_field_id: field.id)
      return nil unless val

      Date.parse(val.value) rescue nil
    end

    def calc_diff_start(planned_start, real_start)
      return nil unless planned_start && real_start

      delta = real_start.to_time - planned_start.to_time
      delta + (delta <=> 0)
    end

    def calc_diff_end(planned_end, real_end)
      return nil unless real_end && planned_end

      delta = real_end.to_time - planned_end.to_time
      delta + (delta <=> 0)
    end

    def calc_diff_duration(planned_start, planned_end, real_start, real_end)
      return nil unless real_start && real_end

      return nil unless planned_start && planned_end

      real = real_end.to_time - real_start.to_time
      planned = planned_end - planned_start
      delta = real - planned
      delta + (delta <=> 0)
    end
  end
end
