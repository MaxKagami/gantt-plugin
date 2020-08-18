module Gantt
  class ProjectTreeQuery
    attr_reader :root_project, :filter

    def initialize(project:, filter: nil)
      @filter = filter
      @root_project = project
      @projects = {}
      @issues = {}
    end

    def call
      recurse_projects([root_project])
    end

    private

    def recurse_projects(prjs)
      # TODO: apply baselines & sources
      @filter ||= GanttIssueSetting.find_by(
        project_id: root_project,
        user_id: User.current&.id,
        issue_id: nil
      )&.query_params
        .yield_self { |q| JSON.parse(q || '{}') } || {}
      prjs.each_with_object([]) do |prj, list|
        obj = Gantt::TreeNode.new(project: prj)
        obj.issues = recurse_issues(prj.issues.where(parent_id: nil))
          .yield_self { |issues| filtrate(issues) }
        obj.children = recurse_projects(prj.children)
        list << obj
      end
    end

    def recurse_issues(isss)
      pos = 1
      isss.each_with_object([]) do |iss, list|
        obj = Gantt::TreeNode.new(issue: iss, position: pos)
        pos += 1
        obj.issues = recurse_issues(iss.children.where(parent_id: iss.id))
          .yield_self { |issues| filtrate(issues) }
        list << obj
      end
    end

    FILTERS = {
      project: :project_id,
      assigned_to: :assigned_to_id,
      status: :status_id,
      tracker: :tracker_id
    }.freeze

    def filtrate(issues)
      return issues if filter.blank?

      issues.select do |issue|
        filter
          .map { |k, v| v.blank? ? true : issue.issue&.send(FILTERS[k.to_sym]).to_s.in?(v) }
          .inject(true) { |sum, i| sum && i }
      end
    end

    def project(id)
      projects([id]).first
    end

    def projects(*ids)
      non_loaded = ids.reject { |id| @projects.key?(id) }
      Project.where(id: non_loaded).each { |prj| @projects[prj.id] = prj } unless non_loaded.empty?
      @projects.slice(*ids).values
    end

    def issue(id)
      issues([id]).first
    end

    def issues(ids)
      non_loaded = ids.reject { |id| @issues.key?(id) }
      Issue.where(id: non_loaded).each { |iss| @issues[iss.id] = iss } unless non_loaded.empty?
      @issues.slice(*ids).values
    end
  end
end
