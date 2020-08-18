class GanttController < ApplicationController
  # accept_api_auth :index, :issues, :projects, :project_issues, :change_issue_relation_delay,
  #   :reschedule_project, :issue_up, :issue_down
  menu_item :gantt

  RELATION_TYPES_TO_LOAD = %w[relates blocks blocked precedes follows start_to_start
                              finish_to_finish start_to_finish].freeze

  # before_action :find_optional_project, except: %i[reschedule_project project_issues]
  # before_action :find_opened_project, except: [:reschedule_project]

  # before_action :authorize, if: proc { @project.present? }
  # before_action :authorize_global, if: proc { @project.nil? }

  # before_action :check_rest_api_enabled, only: [:index]
  # before_action :find_relation, only: [:change_issue_relation_delay]

  include_query_helpers
  helper :custom_fields

  def index
    @print = params[:print]
    @print = nil if @print.blank?
    @loader = Gantt::QueryLoadQuery.new(params: params)
    @project = @loader.load_project
    return render_403 unless check_auth(@project, params)

    @loader.load_baseline
    @loader.load_query
  end

  def update_width
    @project = Project.find_by(id: params[:project_id])
    return(render json: { err: :not_found }, status: 404) unless @project

    setting = GanttIssueSetting.find_by(user_id: User.current.id, issue_id: nil, project_id: @project.id)
    setting ||= GanttIssueSetting.create(user_id: User.current.id, issue_id: nil, project_id: @project.id)
    setting.update(column_settings: setting.column_settings.merge(params[:name] => params[:value]))
    render json: { html: '' }
  end

  def new_task
    project = Project.find_by(id: params[:project_id])
    return(render json: { err: :not_found }, status: 404) unless project

    issue = GanttIssueForm.new(Gantt::NewIssueStruct.new(project_id: project.id, author_id: User.current.id))

    setting = GanttIssueSetting.find_by(user_id: User.current.id, issue_id: nil, project_id: project.id)
    setting ||= GanttIssueSetting.create(user_id: User.current.id, issue_id: nil, project_id: project.id)
    render json: { html: Gantt::Diagram::NewIssueCell.new(issue, setting: setting).call(:show) }
  end

  def create_task
    project = Project.find_by(id: params[:project_id])
    issue = GanttIssueForm.new(Gantt::NewIssueStruct.new(new_issue_params))
    return render(json: { error: :validation_error }) unless issue.validate(new_issue_params)

    issue.save
    respond_to do |format|
      format.json do
        @loader = Gantt::QueryLoadQuery.new(params: params.merge(project_id: project.id.to_s))
        @loader.load_project

        @loader.load_baseline
        @loader.load_query
        render json: {
          status: :ok,
          html: Gantt::Diagram::LayoutCell.new(
            @loader,
            project: project,
            context: { current_user: User.current, parent_controller: params[:controller] }
          ).call
        }
      end
    end
  end

  def filter_values
    project = Project.find_by(id: params[:project_id])
    return(render json: { err: :not_found }, status: 404) unless project

    setting = GanttIssueSetting.find_by(user_id: User.current.id, issue_id: nil, project_id: project.id)
    setting ||= GanttIssueSetting.create(user_id: User.current.id, issue_id: nil, project_id: project.id)
    render json: { html: Gantt::Diagram::FilterCell.new(params, setting: setting).call(:show) }
  end

  def apply_filter
    @project = Project.find_by(id: params[:project_id])
    Gantt::UpdateQueryParams.new.call(project: @project, user: User.current, params: params)
    setting = GanttIssueSetting.find_by(user_id: User.current.id, issue_id: nil, project_id: @project.id)
    setting ||= GanttIssueSetting.create(user_id: User.current.id, issue_id: nil, project_id: @project.id)
    render json: { html: Gantt::Diagram::FilterCell.new(params, setting: setting).call(:apply) }
  end
 
  def projects_list
    render json: { html: Gantt::Diagram::ProjectIndexCell.new.call(:show) }
  end

  def chat_modal
    render json: { html: Gantt::Diagram::ChatModalCell.new.call(:assigned) }
  end

  def import_modal
    render json: { html: Gantt::Diagram::ExcelImportCell.new.call(:show) }
  end
 
  def move_after
    issue = GanttIssueSetting.find_by(user_id: User.current.id, issue_id: params[:issue], project_id: params[:project_id])
    params[:items].each do |item_id|
      item = GanttIssueSetting.find_by(user_id: User.current.id, issue_id: item_id, project_id: params[:project_id])
      item.parent_id = issue.parent_id
      item.insert_at(issue.position + 1)
    end

    @loader = Gantt::QueryLoadQuery.new(params: params)
    @project = @loader.load_project
    @loader.apply_params
    @loader.load_baseline
    @loader.load_query
    render json: { html: Gantt::Diagram::LayoutCell.new(@loader, context: { current_user: User.current }).call } 
  end

  def make_children
  end

  def issues_up
    setting = Gantt::LoadIssueSetting.new
      .call(user: User.current, project: @project, issue: issue, parent: issue.parent)
    raise StandartError, setting.failure if setting.failure?
  end

  def color_rows

  end

  private

  def new_issue_params
    params[:issue] || {}
  end

  def check_auth(project, param)
    return false if project && !User.current.allowed_to?(:view_gantt, project)

    return false if project.nil? && !User.current.allowed_to_globally?(:view_global_gantt)

    return false unless authorize(param[:controller], param[:action], project.nil?)

    true
  end
end
