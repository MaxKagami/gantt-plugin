module Gantt
  class IssueFieldQuery
    attr_reader :project, :name, :user, :avail_cols, :cols

    CALL_FIELDS = %i[main_project parent_category root_category parent_project].freeze
    REF_FIELDS = %i[project parent status tracker priority fixed_version easy_closed_by category assigned_to
                    author activity].freeze
    STAT_FIELDS = %i[status_time_1 status_time_8 status_time_2 status_time_43 status_time_4 status_time_3 status_time_5
                     status_time_6 status_time_53 status_time_44 status_time_45 status_time_52 status_time_11
                     status_time_46 status_time_47 status_time_51 status_time_48 status_time_15 status_time_19
                     status_time_49 status_time_28 status_time_50 status_time_30 status_time_31 status_time_54
                     status_time_37 status_time_33 status_time_34 status_time_35 status_count_1 status_count_8
                     status_count_2 status_count_43 status_count_4 status_count_3 status_count_5 status_count_6
                     status_count_53 status_count_44 status_count_45 status_count_52 status_count_11 status_count_46
                     status_count_47 status_count_51 status_count_48 status_count_15 status_count_19 status_count_49
                     status_count_28 status_count_50 status_count_30 status_count_31 status_count_54 status_count_37
                     status_count_33 status_count_34 status_count_35].freeze
    ISSUE_FIELDS = %i[subject start_date due_date created_on updated_on easy_status_updated_on].freeze
    FIELDS = %i[  open_duration_in_hours easy_last_updated_by done_ratio relations description
                  attachments closed_on easy_due_date_time_remaining
                  id watchers tags easy_next_start status_time_current
                  issue_easy_sprint_relation.easy_sprint easy_story_points easy_email_to easy_email_cc
                  easy_helpdesk_project_monthly_hours easy_helpdesk_mailbox_username easy_helpdesk_need_reaction
                  easy_helpdesk_ticket_owner easy_response_date_time_remaining easy_due_date_time
                  easy_response_date_time].freeze + CALL_FIELDS + REF_FIELDS + ISSUE_FIELDS

    def initialize(project, name, user: nil)
      @project = project
      @name = name
      @user = user || User.current
    end

    def values
      return cf_values if cf?

      return ref_values if ref?

      return [] if field?

      nil
    end

    def columns
      set = GanttIssueSetting.find_by(project_id: project.id, user_id: user.id, issue_id: nil)
      set&.column_names&.yield_self { |s| begin; YAML.safe_load(s); rescue; nil; end } || default_columns
    end

    def available_columns
      query.available_columns
    end

    private

    def default_columns
      query.columns.map(&:name)
    end

    def field?
      name.to_sym.in?(ISSUE_FIELDS)
    end

    def cf?
      name.to_s.start_with?('cf_')
    end

    def ref?
      name.to_sym.in?(REF_FIELDS)
    end

    def field_values
      nil
    end

    def ref_values
      # project parent status tracker priority fixed_version easy_closed_by category assigned_to author activity
      refs = {
        project: Project,
        status: IssueStatus,
        tracker: Tracker,
        priority: IssuePriority,
        easy_closed_by: User,
        category: IssueCategory,
        assigned_to: User,
        author: User,
        activity: TimeEntryActivity
      }

      # &.active&.sorted
      _vals = refs[name.to_sym].all.map { |i| OpenStruct.new(name: i.name, id: i.id) }.sort_by(&:name) || []
    end

    def cf_values
      cf_id = name.to_s.match(/cf_(\d+)\Z/).try(:[], 1)
      return [] unless cf_id

      cf = IssueCustomField.find(cf_id.to_i)
      cf.possible_values
    end

    def query
      q = EasyIssueQuery.new(name: '_')
      q.project_id = project&.id
      q.from_params({})
      q
    end

    def columns_from_query
      query.available_columns
    end
  end
end
