module Gantt
  class UpdateIssueFoldState
    include Dry::Transaction

    step :prepare
    step :store

    private

    def prepare(issue_id:)
      issue = Issue.find_by(id: issue_id)
      return Failure(:issue_not_found) unless issue

      setting = GanttIssueSetting.find_by(issue_id: issue.id, user_id: User.current.id, project_id: issue.project_id)
      setting ||= GanttIssueSetting.create(issue_id: issue.id, user_id: User.current.id, project_id: issue.project_id)
      Success(issue: issue, setting: setting)
    end

    def store(issue:, setting:)
      unless issue.children.empty?
        bul = !setting.hide_children
        setting.update(hide_children: bul)
      end
      Success(:ok)
    end
  end
end
