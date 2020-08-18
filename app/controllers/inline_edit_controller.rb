class InlineEditController < ApplicationController
  def show
    @loader = Gantt::QueryLoadQuery.new(params: params)
    @project = @loader.load_project

    @loader.load_baseline
    @loader.load_query
    issue = Issue.find(params[:id])
    render json: {
      html: Gantt::Diagram::FieldCell.new(
        issue,
        setting: GanttIssueSetting.find_by(issue_id: issue.id, project_id: @loader.project.id, user_id: User.current.id),
        # field: @loader.query.columns.find { |col| col&.name.to_s == params[:name] }&.name&.to_s
        field: params[:name].to_s
      ).call(:edit)
    }
  end

  def update
    @loader = Gantt::QueryLoadQuery.new(params: params)
    @project = @loader.load_project

    @loader.load_baseline
    @loader.load_query
    issue = Issue.find(params[:id])
    lvl = 0
    iss = issue
    while iss.parent
      iss = iss.parent
      lvl += 1
    end
    prj = iss.project
    while prj.parent
      prj = prj.parent
      lvl += 1
    end
    lvl += 1
    Gantt::UpdateIssueField.new.call(issue_id: issue.id, name: params[:name], val: params[:value]) do |res|
      res.success do |val|
        render json: {
          html: Gantt::Diagram::FieldCell.new(
            val,
            field: params[:name],
            # field: @loader.query.columns.find { |col| col&.name.to_s == params[:name] }&.name&.to_s,
            setting: GanttIssueSetting.find_by(issue_id: issue.id, project_id: @project.id, user_id: User.current.id),
            level: lvl,
            context: { parent_controller: params[:controller] }
          ).call(:internal)
        }
      end
      res.failure do |err|
        render json: { error: err }
      end
    end
  end

  def switch_close
    issue = Issue.find(params[:id])

    # Gantt::UpdateIssueField.new.call(issue_id: issue.id, name: params[:name], val: params[:value]) do |res|
    Gantt::UpdateIssueFoldState.new.call(issue_id: issue.id) do |res|
      res.success do |_val|
        loader = Gantt::QueryLoadQuery.new(params: params.merge(project_id: issue.project_id.to_s))
        loader.load_project

        loader.load_baseline
        loader.load_query
        render json: {
          html: Gantt::Diagram::LayoutCell.new(
            loader,
            context: { current_user: User.current, parent_controller: params[:controller] }
          ).call
        }
      end
      res.failure do |err|
        render json: { error: err }
      end
    end
  end

  def new_issue
    @loader = Gantt::QueryLoadQuery.new(params: params)
    @project = @loader.load_project

    @loader.load_baseline
    @loader.load_query
    issue = Issue.find(params[:id])
    render json: {
      html: Gantt::Diagram::FieldCell.new(
        issue,
        setting: GanttIssueSetting.find_by(issue_id: issue.id, project_id: @loader.project.id, user_id: User.curreent.id),
        # field: @loader.query.columns.find { |col| col&.name.to_s == params[:name] }&.name&.to_s
        field: params[:name].to_s
      ).call(:edit)
    }
  end

  private

  def check_auth(project, param)
    return false if project && !User.current.allowed_to?(:view_gantt, project)

    return false if project.nil? && !User.current.allowed_to_globally?(:view_global_gantt)

    return false unless authorize(param[:controller], param[:action], project.nil?)

    true
  end
end
