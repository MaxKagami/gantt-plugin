module Gantt::Diagram
  class NewIssueCell < Cell::ViewModel
    self.view_paths = ['plugins/ganttiot/app/cells']

    property :project_id

    def show
      render
    end

    def avail_tasks
      Project.find(project_id).issues.map { |u| [u.id, u.subject] }
    end

    def avail_users
      Project.find(project_id).users.map { |u| [u.id, u.name] }
    end

    def avail_trackers
      Project.find(project_id).trackers.map { |u| [u.id, u.name] }
    end
  end
end
