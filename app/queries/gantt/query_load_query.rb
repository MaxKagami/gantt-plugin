module Gantt
  class QueryLoadQuery
    attr_reader :params, :project, :query, :baseline, :filter, :names

    def initialize(params:)
      @params = params
    end

    def call
      load_project
      load_baseline
      load_query
      load_issues
      self
    end

    def load_project
      if params[:set_filter] == '1' && params[:project_id].present? && params[:project_id].start_with?('=', '!*', '*')
        return
      end

      @project = Project.find_by(id: params[:project_id])
    end

    def load_baseline
      id = params[:baseline] || params[:id]
      return unless id

      @baseline = @project.easy_baselines.find_by(identifier: id)
    end

    def apply_params
      setting = GanttIssueSetting.find_by(project_id: @project.id, issue_id: nil, user_id: User.current.id)
      @filter = JSON.parse(setting&.query_params || '{}') || {}
      @names = YAML.load(setting&.column_names || '--- []')
    end

    def load_query
      if params[:query_id].present?
        load_query_by_id
      else
        @query = query_class.new(name: '_')
        query.from_params(params)
        # query.column_names = params[:query][:column_names] if params[:query] && params[:query][:column_names].present?
        # query.switch_period_zoom_to(params[:query][:period_zoom]) if params[:query] && params[:query][:period_zoom]
        query.column_names = params[:query][:column_names] if params.dig(:query, :column_names).present?
        query.switch_period_zoom_to(params[:query][:period_zoom]) if params.dig(:query, :period_zoom)
        query.project = @project
        # query.from_params(params)
        query
      end

      query.available_columns << EasyQueryColumn.new(:issue_diff_start, is_for_all: true)
      query.available_columns << EasyQueryColumn.new(:issue_diff_end, is_for_all: true)
      query.available_columns << EasyQueryColumn.new(:issue_diff_duration, is_for_all: true)
      # TODO: !!! restore !!!  @query.opened_project = @opened_project if @opened_project
    end

    def load_issues
      query.entities
    end

    private

    def load_query_by_id
      cond = 'project_id IS NULL'

      if @project
        cond << " OR project_id = #{@project.id}"

        # In Easy Project query can be defined for subprojects
        unless @project.root?
          ancestors = @project.ancestors.select(:id).to_sql
          cond << " OR (is_for_subprojects = #{Project.connection.quoted_true} AND project_id IN (#{ancestors}))"
        end
      end

      @query = query_class.where(cond).find_by(id: params[:query_id])
      raise ActiveRecord::RecordNotFound if query.nil?
      raise Unauthorized unless query.visible?

      query.project = @project
      sort_clear
    end

    def query_class
      @project ? EasyIssueQuery : EasyProjectQuery
    end

    def find_optional_project
      # Easy query workaround
      if params[:set_filter] == '1' && params[:project_id].present? && params[:project_id].start_with?('=', '!*', '*')
        return
      end

      super
    end

    def find_opened_project
      return @opened_project = Project.find(params[:opened_project_id]) if params[:opened_project_id].present?

      @opened_project = @project
    rescue ActiveRecord::RecordNotFound
      render_404
    end
  end
end
