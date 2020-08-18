class BaselineController < ApplicationController
  def index
  end

  def create
    # TODO: Form?
    opts = params[:baselines] || {}
    loader = Gantt::QueryLoadQuery.new(params: params)
    loader.load_project
    project = loader.project
    # return(render_403) unless check_auth(project, params)

    result = Gantt::Baseline::CreateFromProject.new.call(project: project, params: opts)
    return redirect_to(:back) if result.failure?

    # return render(text: result.failure, status: 422) if result.failure?

    redirect_to gantt_index_path(project&.id)
    # render json: { project: project&.id, baseline: result.value!.id }
  end

  def show
    @loader = Gantt::QueryLoadQuery.new(params: params)
    @project = @loader.load_project
    return render_403 unless check_auth(@project, params)

    @loader.load_query
    @baseline = @project.easy_baselines.find_by(identifier: params[:id])
  end

  def renew_dates
    @loader = Gantt::QueryLoadQuery.new(params: params)
    @project = @loader.load_project
    baseline = @project.easy_baselines.find_by(identifier: params[:id])
    rez = Gantt::Baseline::SaveIssueDates.new.call(baseline: baseline)
    return redirect_to(baseline_path(@project, baseline)) if rez.success?

    render json: { error: rez.failure }, status: 422
  end

  private

  def check_auth(project, param)
    return false if project && !User.current.allowed_to?(:view_gantt, project)

    return false if project.nil? && !User.current.allowed_to_globally?(:view_global_gantt)

    return false unless authorize(param[:controller], param[:action], project.nil?)

    true
  end
end
